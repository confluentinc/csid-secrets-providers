_empty :=
_space := $(_empty) $(empty)

# Use this variable to specify a different make utility (e.g. remake --profile)
# Note: not using $(MAKE) $(MAKE_ARGS) here since that runs inside container (different OS)
DOCKER_MAKE ?= make

# List of base images, cannot have colons, replace with a bang
DOCKER_BASE_IMAGES ?= $(subst :,!,$(shell perl -Xlne 's/^FROM\s*(--platform=\S*)?\s*([A-Za-z0-9.\-\/:]*).*/$$2/ and print' Dockerfile | uniq))

# Use this variable to specify a different name for the Dockerfile
DOCKER_FILE ?= Dockerfile

# Use this variable to specify a different location for the Dockerfile
DOCKER_FILE_PATH ?= .

# Use this variable to skip pushing docker image to release if it exists already
DOCKER_PUSH_RELEASE_SKIP_IF_PRESENT ?= false

DOCKER_APPEND_ARCH_SUFFIX  ?= false

# Use this variable to specify docker build options
DOCKER_BUILD_OPTIONS ?=
ifeq ($(CI),true)
	DOCKER_BUILD_OPTIONS += --no-cache --progress plain
endif

# Use this variable to specify docker labels
DOCKER_BUILD_LABELS ?=

# These are included in on every image
DOCKER_BUILD_LABELS += --label org.opencontainers.image.created=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
DOCKER_BUILD_LABELS += --label org.opencontainers.image.vendor="Confluent Inc."

# This is populated in cc-begin.mk
ifneq ($(GIT_COMMIT),)
	DOCKER_BUILD_LABELS += --label org.opencontainers.image.revision=$(GIT_COMMIT)
endif

# If running in Semaphore, add some details from the environment variables
ifneq ($(SEMAPHORE_JOB_ID),)
	DOCKER_BUILD_LABELS += --label org.opencontainers.image.url=$(SEMAPHORE_ORGANIZATION_URL)/jobs/$(SEMAPHORE_JOB_ID)
endif
ifneq ($(SEMAPHORE_GIT_PR_SLUG),)
	DOCKER_BUILD_LABELS += --label org.opencontainers.image.source=https://github.com/$(SEMAPHORE_GIT_PR_SLUG)
else ifneq ($(SEMAPHORE_GIT_REPO_SLUG),)
	DOCKER_BUILD_LABELS += --label org.opencontainers.image.source=https://github.com/$(SEMAPHORE_GIT_REPO_SLUG)
endif

# Setup mount options for buildkit
ifneq ($(DOCKER_BUILDKIT),0)
	# See: https://github.com/moby/buildkit/blob/3187d2d056de7e3f976ef62cd548499dc3472a7e/frontend/dockerfile/docs/reference.md#run---mounttypessh
	DOCKER_SSH_MOUNT       ?=
	DOCKER_SSH_AUTH_SOCK   ?=
	# See: https://github.com/moby/buildkit/blob/3187d2d056de7e3f976ef62cd548499dc3472a7e/frontend/dockerfile/docs/reference.md#run---mounttypesecret
	DOCKER_NETRC_MOUNT     ?=
	DOCKER_AWS_MOUNT       ?=
ifneq ($(DOCKER_SSH_MOUNT),)
ifneq ($(DOCKER_SSH_AUTH_SOCK),)
	DOCKER_BUILD_OPTIONS += --ssh default=$(DOCKER_SSH_AUTH_SOCK)
else
	DOCKER_BUILD_OPTIONS += --ssh default
endif
endif
ifneq ($(DOCKER_NETRC_MOUNT),)
	DOCKER_BUILD_OPTIONS += --secret id=netrc,src=$(HOME)/.netrc
endif
ifneq ($(DOCKER_AWS_MOUNT),)
	DOCKER_BUILD_OPTIONS += --secret id=aws,src=$(HOME)/.aws/credentials
endif
endif

DOCKER_BUILDKIT_CACHE = docker-buildkit-cache
ifneq ($(DOCKER_SHARED_TARGET), $(empty))
DOCKER_CACHE_SOURCE = --cache-from=type=local,src=$(DOCKER_BUILDKIT_CACHE)
endif

ifeq ($(DOCKER_BUILD_MULTIARCH), true)
ifeq ($(DOCKER_BUILDKIT),0)
$(error DOCKER_BUILDKIT cannot be disabled when DOCKER_BUILD_MULTIARCH is enabled)
endif
QEMU_INIT_SCRIPT=$(MK_INCLUDE_BIN)/init-docker-builder.sh
DOCKER_BUILDER = buildx-builder
ARCH ?= amd64
ARCH_SUFFIX = -$(ARCH)
DOCKER_RELEASE_MULTIARCH = true
else
ARCH_SUFFIX = $(empty)
endif

set_arch_suffix =
ifeq ($(DOCKER_APPEND_ARCH_SUFFIX), true)
set_arch_suffix = true
endif
ifeq ($(DOCKER_RELEASE_MULTIARCH), true)
set_arch_suffix = true
endif

ifeq ($(set_arch_suffix), true)
ARCH_SUFFIX = -$(ARCH)
endif

# Image Name
IMAGE_NAME ?= unknown
ifeq ($(IMAGE_NAME),unknown)
$(error IMAGE_NAME must be set)
endif

# Image Version
#  If we're on CI and a release branch, build with the bumped version
ifeq ($(CI),true)
ifneq ($(RELEASE_BRANCH),$(_empty))
IMAGE_VERSION ?= $(BUMPED_VERSION)
else
IMAGE_VERSION ?= $(VERSION)
endif
else
IMAGE_VERSION ?= $(VERSION)
endif
IMAGE_VERSION_NO_V := $(shell echo $(IMAGE_VERSION) | sed -e 's/^v//')

# If we got a valid image version, add it as a label
ifneq ($(IMAGE_VERSION),)
	DOCKER_BUILD_LABELS += --label org.opencontainers.image.version=$(IMAGE_VERSION)
endif

IMAGE_REPO ?= confluentinc
ifeq ($(IMAGE_REPO),$(_empty))
BUILD_PATH ?= $(IMAGE_NAME)
else
BUILD_PATH ?= $(IMAGE_REPO)/$(IMAGE_NAME)
endif
BUILD_TAG_NOARCH ?= $(BUILD_PATH):$(IMAGE_VERSION)
BUILD_TAG_LATEST_NOARCH ?= $(BUILD_PATH):latest
BUILD_TAG ?= $(BUILD_TAG_NOARCH)$(ARCH_SUFFIX)
BUILD_TAG_LATEST ?= $(BUILD_TAG_LATEST_NOARCH)$(ARCH_SUFFIX)

# By default, cc-docker does not tag and push images with "latest" tag to remote repo
# If a service has to use the "latest" version of an image, set this variable to true at the root level
ALLOW_BUILD_LATEST_TAG ?= false

# Set targets for standard commands
CACHE_DOCKER_BASE_IMAGES ?= true
ifeq ($(CACHE_DOCKER_BASE_IMAGES),true)
INIT_CI_TARGETS += cache-docker-base-images
endif

RELEASE_POSTCOMMIT += push-docker
BUILD_TARGETS += build-docker
CLEAN_TARGETS += clean-images

DOCKER_BUILD_PRE ?=
DOCKER_BUILD_POST ?=

ifneq ($(DOCKER_SHARED_TARGET), $(empty))
DOCKER_BUILD_PRE += build-shared-target
endif

IMAGE_SIGNING_URL ?= 'https://imagesigning.prod.cire.aws.internal.confluent.cloud/v1/oidc/sign' 
IMAGE_SIGNING_ENABLED ?= true
ifeq ($(IMAGE_SIGNING_ENABLED), true)
RELEASE_POSTCOMMIT += sign-image
endif

.PHONY: show-docker
## Show docker variables
show-docker:
	@echo "DOCKER_BASE_IMAGES: $(DOCKER_BASE_IMAGES)"
	@echo "IMAGE_NAME: $(IMAGE_NAME)"
	@echo "IMAGE_VERSION: $(IMAGE_VERSION)"
	@echo "IMAGE_REPO: $(IMAGE_REPO)"
	@echo "BUILD_TAG: $(BUILD_TAG)"
	@echo "BUILD_TAG_LATEST: $(BUILD_TAG_LATEST)"
	@echo "DOCKER_REPO: $(DOCKER_REPO)"
	@echo "DOCKER_BUILD_OPTIONS: $(DOCKER_BUILD_OPTIONS)"
	@echo "DOCKER_BUILD_LABELS: $(DOCKER_BUILD_LABELS)"
	@echo "DOCKER_FILE: $(DOCKER_FILE)"
	@echo "DOCKER_FILE_PATH: $(DOCKER_FILE_PATH)"
	@echo "DOCKER_PUSH_RELEASE_SKIP_IF_PRESENT: $(DOCKER_PUSH_RELEASE_SKIP_IF_PRESENT)"
	@echo "ALLOW_BUILD_LATEST_TAG: $(ALLOW_BUILD_LATEST_TAG)"

.PHONY: cache-docker-base-images $(DOCKER_BASE_IMAGES:%=docker-cache.%)
## On Semaphore, use the cache to store/restore docker image to reduce transfer costs.
## - use gzip --no-name so the bits are deterministic,
## - always pull, this checks for updates, e.g. 'latest' tag could have been updated,
## - update cache if bits are different.
cache-docker-base-images: $(DOCKER_BASE_IMAGES:%=docker-cache.%)
$(DOCKER_BASE_IMAGES:%=docker-cache.%):
	$(eval image := $(subst !,:,$(@:docker-cache.%=%)))
	cache restore $(image)
	-test ! -f base-image.tgz || docker load -i base-image.tgz
	-mv base-image.tgz base-image-prev.tgz

	# Pull Docker image and check if it's up to date
	docker pull $(image) 2>&1 | tee /tmp/cached-docker-base.log

	# Only cache image and make tarball if we pulled a newer version
	if grep -q "Status: Downloaded newer image" /tmp/cached-docker-base.log; then \
		set -o pipefail && docker save $(image) | gzip --no-name > base-image.tgz && \
		cache delete $(image) && cache store $(image) base-image.tgz; \
	fi
	rm -f base-image*.tgz

.PHONY: cache-restore-docker-base-images $(DOCKER_BASE_IMAGES:%=docker-cache.%)
cache-restore-docker-base-images: $(DOCKER_BASE_IMAGES:%=restore-docker-cache.%)
$(DOCKER_BASE_IMAGES:%=restore-docker-cache.%):
	$(eval image := $(subst !,:,$(@:restore-docker-cache.%=%)))
	cache restore $(image)

.PHONY: ssh-add
ifneq ($(DOCKER_SSH_MOUNT),)
ifneq ($(DOCKER_SSH_AUTH_SOCK),)
ssh-add:
	@echo "SSH socket specified -- skipping adding keys"
else
ssh-add:
	@echo "Adding keys to agent for ssh support"
	@ssh-add -l | grep -q '@confluent.io' || ssh-add || (echo "Unable to add default identities. Manually add keys to the agent using ssh-add."; exit 1)
endif
endif

ifeq ($(DOCKER_BUILD_MULTIARCH), true)
.PHONY: install-qemu-static
install-qemu-static:
	$(QEMU_INIT_SCRIPT) $(DOCKER_BUILDER)

.PHONY: build-shared-target
build-shared-target: install-qemu-static
ifneq ($(DOCKER_SHARED_TARGET), $(empty))
	docker buildx build $(DOCKER_BUILD_OPTIONS) $(DOCKER_BUILD_LABELS) \
		--target=$(DOCKER_SHARED_TARGET) \
		--cache-to=type=local,mode=max,dest=$(DOCKER_BUILDKIT_CACHE) .
endif

.PHONY: build-docker-arch
build-docker-arch: install-qemu-static
	docker buildx build $(DOCKER_BUILD_OPTIONS) $(DOCKER_BUILD_LABELS) \
		--label version.$(IMAGE_REPO).$(IMAGE_NAME)=$(IMAGE_VERSION) \
		--build-arg version=$(IMAGE_VERSION) \
		$(DOCKER_CACHE_SOURCE) \
		--platform linux/$(ARCH) --load \
		-t $(BUILD_TAG) \
		-f $(DOCKER_FILE) $(DOCKER_FILE_PATH)
	@echo 'Built single-arch image $(BUILD_TAG) - run `make push-docker` to build the multi-arch manifest'
	$(MAKE) $(MAKE_ARGS) store-docker-version IMAGE_VERSION=$(IMAGE_VERSION) ARCH=$(ARCH)
endif

.PHONY: build-docker-image
## Build just the docker image
build-docker-image: ssh-add .gitconfig .netrc .ssh $(DOCKER_BUILD_PRE)
ifeq ($(GO_USE_VENDOR),-mod=vendor)
ifneq ($(CI),true)
	@$(MAKE) $(MAKE_ARGS) deps
endif
endif
ifeq ($(DOCKER_BUILD_MULTIARCH), true)
	$(MAKE) $(MAKE_ARGS) build-docker-arch ARCH=arm64	
	$(MAKE) $(MAKE_ARGS) build-docker-arch ARCH=amd64
else
	@docker build $(DOCKER_BUILD_OPTIONS) $(DOCKER_BUILD_LABELS) \
		--label version.$(IMAGE_REPO).$(IMAGE_NAME)=$(IMAGE_VERSION) \
		--build-arg version=$(IMAGE_VERSION) \
		-t $(BUILD_TAG) \
		-f $(DOCKER_FILE) $(DOCKER_FILE_PATH)
	$(MAKE) $(MAKE_ARGS) store-docker-version IMAGE_VERSION=$(IMAGE_VERSION) ARCH=$(ARCH)
endif
	rm -rf .netrc .ssh .aws .config .gitconfig
ifneq ($(DOCKER_BUILD_POST),)
	$(MAKE) $(MAKE_ARGS) $(DOCKER_BUILD_POST)
endif

.PHONY: build-docker
ifeq ($(BUILD_DOCKER_OVERRIDE),)
build-docker: build-docker-image
else
build-docker: ssh-add $(BUILD_DOCKER_OVERRIDE)
endif

.PHONY: store-docker-version
ifeq ($(STORE_DOCKER_OVERRIDE),)
store-docker-version:
ifeq ($(CI),true)
	docker image save $(BUILD_TAG) | gzip | \
		artifact push project /dev/stdin -d docker/$(BRANCH_NAME)/$(IMAGE_VERSION)$(ARCH_SUFFIX).tgz --force
endif
else
store-docker-version: $(STORE_DOCKER_OVERRIDE)
endif

.PHONY: restore-docker-version
ifeq ($(RESTORE_DOCKER_OVERRIDE),)
restore-docker-version:
ifeq ($(CI),true)
	artifact pull project docker/$(BRANCH_NAME)/$(IMAGE_VERSION)$(ARCH_SUFFIX).tgz -d /dev/stdout --force | \
		gunzip | docker image load
endif
else
restore-docker-version: $(RESTORE_DOCKER_OVERRIDE)
endif

.PHONY: tag-docker
ifeq ($(TAG_DOCKER_OVERRIDE),)
ifeq ($(CI),true)
ifeq ($(ALLOW_BUILD_LATEST_TAG),true)
tag-docker: tag-docker-version-to-release tag-docker-latest
else
tag-docker: tag-docker-version-to-release
endif
else
tag-docker: tag-docker-version
endif
else
tag-docker: $(TAG_DOCKER_OVERRIDE)
endif

ifeq ($(DOCKER_RELEASE_MULTIARCH), true)
.PHONY: tag-docker-version-arch
## tag mult-arch docker image for for dirty repo (GAR)
tag-docker-version-arch:
else
.PHONY: tag-docker-version
## tag docker image for for dirty repo (GAR)
tag-docker-version:
endif
	@echo 'create docker tag $(BUILD_PATH):$(IMAGE_VERSION)$(ARCH_SUFFIX) for dirty repo'
	docker tag $(BUILD_TAG) $(DEVPROD_NONPROD_GAR_REPO)/$(BUILD_PATH):$(IMAGE_VERSION)$(ARCH_SUFFIX)

ifeq ($(DOCKER_RELEASE_MULTIARCH), true)
.PHONY: tag-docker-version-arch-to-release
## tag multi-arch docker image version for release repo
tag-docker-version-arch-to-release:
else
.PHONY: tag-docker-version-to-release
## tag docker image version for release repo
tag-docker-version-to-release:
endif
	@echo 'create docker tag $(BUILD_PATH):$(IMAGE_VERSION)$(ARCH_SUFFIX) for release repo'
	docker tag $(BUILD_TAG) $(DOCKER_REPO)/$(BUILD_PATH):$(IMAGE_VERSION)$(ARCH_SUFFIX)

ifeq ($(DOCKER_RELEASE_MULTIARCH), true)
.PHONY: tag-docker-latest-arch
tag-docker-latest-arch:
else
.PHONY: tag-docker-latest
tag-docker-latest:
endif
	@echo 'create docker tag $(BUILD_TAG_LATEST)'
	docker tag $(BUILD_TAG) $(DOCKER_REPO)/$(BUILD_TAG_LATEST)

.PHONY: push-docker
ifeq ($(PUSH_DOCKER_OVERRIDE),)
ifeq ($(CI),true)
ifeq ($(ALLOW_BUILD_LATEST_TAG),true)
push-docker: push-docker-version-to-release push-docker-latest
else
push-docker: push-docker-version-to-release
endif
else
push-docker: push-docker-version
endif
else
push-docker: $(PUSH_DOCKER_OVERRIDE)
endif

ifeq ($(DOCKER_RELEASE_MULTIARCH), true)
.PHONY: push-docker-latest-arch
push-docker-latest-arch: tag-docker-latest-arch
else
.PHONY: push-docker-latest
push-docker-latest: tag-docker-latest
endif
	@echo 'push latest to $(DOCKER_REPO)'
	aws ecr batch-delete-image --registry-id $(DEVPROD_PROD_AWS_ACCOUNT) \
		--repository-name $(DEVPROD_PROD_ECR_PREFIX)/$(BUILD_PATH) \
		--image-ids imageTag=latest$(ARCH_SUFFIX) --region us-west-2
	docker push $(DOCKER_REPO)/$(BUILD_TAG_LATEST) || docker push $(DOCKER_REPO)/$(BUILD_TAG_LATEST)

ifeq ($(DOCKER_RELEASE_MULTIARCH), true)
.PHONY: push-docker-version-arch
## Push multi-arch docker image version to dirty repo (GAR)
push-docker-version-arch: restore-docker-version tag-docker-version-arch
else
.PHONY: push-docker-version
## Push docker image version to dirty repo (GAR)
push-docker-version: restore-docker-version tag-docker-version
endif
	@echo 'push $(BUILD_TAG) to $(DEVPROD_NONPROD_GAR_REPO)'
	docker push $(DEVPROD_NONPROD_GAR_REPO)/$(BUILD_TAG) || docker push $(DEVPROD_NONPROD_GAR_REPO)/$(BUILD_TAG)

ifeq ($(DOCKER_RELEASE_MULTIARCH), true)
.PHONY: push-docker-version-arch-to-release
## Push multi-arch docker image version to release repo (ECR)
push-docker-version-arch-to-release: restore-docker-version tag-docker-version-arch-to-release
else
.PHONY: push-docker-version-to-release
## Push docker image version to release repo (ECR)
push-docker-version-to-release: restore-docker-version tag-docker-version-to-release
endif
	@echo 'push $(BUILD_TAG) to $(DOCKER_REPO)'
ifeq ($(DOCKER_PUSH_RELEASE_SKIP_IF_PRESENT), true)
	docker pull $(DOCKER_REPO)/$(BUILD_TAG) || docker push $(DOCKER_REPO)/$(BUILD_TAG) || docker push $(DOCKER_REPO)/$(BUILD_TAG)
else
	docker push $(DOCKER_REPO)/$(BUILD_TAG) || docker push $(DOCKER_REPO)/$(BUILD_TAG)
endif

ifeq ($(DOCKER_RELEASE_MULTIARCH), true)
# All of these targets explicitly set IMAGE_VERSION, because they run after CI has pushed a new release branch.
# Recursive calls to make at this point recompute the bumped version and bump it *again*, resulting in errors.
# Long-term the fix is to not call make recursively and find another way to DRY these up.
.PHONY: tag-docker-version
tag-docker-version:
	$(MAKE) $(MAKE_ARGS) tag-docker-version-arch ARCH=amd64 IMAGE_VERSION=$(IMAGE_VERSION)
	$(MAKE) $(MAKE_ARGS) tag-docker-version-arch ARCH=arm64 IMAGE_VERSION=$(IMAGE_VERSION)

.PHONY: tag-docker-version-to-release
tag-docker-version-to-release:
	$(MAKE) $(MAKE_ARGS) tag-docker-version-arch-to-release ARCH=amd64 IMAGE_VERSION=$(IMAGE_VERSION)
	$(MAKE) $(MAKE_ARGS) tag-docker-version-arch-to-release ARCH=arm64 IMAGE_VERSION=$(IMAGE_VERSION)

.PHONY: tag-docker-latest
tag-docker-latest:
	$(MAKE) $(MAKE_ARGS) tag-docker-latest-arch ARCH=amd64 IMAGE_VERSION=$(IMAGE_VERSION)
	$(MAKE) $(MAKE_ARGS) tag-docker-latest-arch ARCH=arm64 IMAGE_VERSION=$(IMAGE_VERSION)

.PHONY: push-multiarch-manifest
push-multiarch-manifest:
	# `docker manifest create` doesn't replace an existing manifest the way tagging an image does, so try and delete any existing manifest if it exists locally
	docker manifest rm $(DOCKER_MULTIARCH_MANIFEST) 2&> /dev/null || true
	docker manifest create $(DOCKER_MULTIARCH_MANIFEST) $(DOCKER_MULTIARCH_MANIFEST)-arm64 $(DOCKER_MULTIARCH_MANIFEST)-amd64
	@echo 'Pushed multi-arch image $(DOCKER_MULTIARCH_MANIFEST) to dirty repo'
	docker manifest push $(DOCKER_MULTIARCH_MANIFEST)

.PHONY: push-multiarch-manifest-to-release
push-multiarch-manifest-to-release:
	# `docker manifest create` doesn't replace an existing manifest the way tagging an image does, so try and delete any existing manifest if it exists locally
	docker manifest rm $(DOCKER_MULTIARCH_MANIFEST) 2&> /dev/null || true
	docker manifest create $(DOCKER_MULTIARCH_MANIFEST) $(DOCKER_MULTIARCH_MANIFEST)-arm64 $(DOCKER_MULTIARCH_MANIFEST)-amd64
ifeq ($(findstring $(DEVPROD_PROD_AWS_ACCOUNT), $(DOCKER_MULTIARCH_MANIFEST)), $(DEVPROD_PROD_AWS_ACCOUNT))
	aws ecr batch-delete-image --registry-id $(DEVPROD_PROD_AWS_ACCOUNT) \
		--repository-name $(DEVPROD_PROD_ECR_PREFIX)/$(BUILD_PATH) \
		--image-ids imageTag=latest --region us-west-2
endif
	@echo 'Pushed multi-arch image $(DOCKER_MULTIARCH_MANIFEST) to release repo'
	docker manifest push $(DOCKER_MULTIARCH_MANIFEST)

.PHONY:push-docker-latest
push-docker-latest: 
	$(MAKE) $(MAKE_ARGS) push-docker-latest-arch ARCH=amd64 IMAGE_VERSION=$(IMAGE_VERSION)
	$(MAKE) $(MAKE_ARGS) push-docker-latest-arch ARCH=arm64 IMAGE_VERSION=$(IMAGE_VERSION)
	$(MAKE) $(MAKE_ARGS) push-multiarch-manifest DOCKER_MULTIARCH_MANIFEST=$(DOCKER_REPO)/$(BUILD_PATH):latest

.PHONY:push-docker-version
push-docker-version: 
	$(MAKE) $(MAKE_ARGS) push-docker-version-arch ARCH=amd64 IMAGE_VERSION=$(IMAGE_VERSION)
	$(MAKE) $(MAKE_ARGS) push-docker-version-arch ARCH=arm64 IMAGE_VERSION=$(IMAGE_VERSION)	
	$(MAKE) $(MAKE_ARGS) push-multiarch-manifest DOCKER_MULTIARCH_MANIFEST=$(DEVPROD_NONPROD_GAR_REPO)/$(BUILD_PATH):$(IMAGE_VERSION)

.PHONY:push-docker-version-to-release
push-docker-version-to-release: 
	$(MAKE) $(MAKE_ARGS) push-docker-version-arch-to-release ARCH=amd64 IMAGE_VERSION=$(IMAGE_VERSION)
	$(MAKE) $(MAKE_ARGS) push-docker-version-arch-to-release ARCH=arm64 IMAGE_VERSION=$(IMAGE_VERSION)	
	$(MAKE) $(MAKE_ARGS) push-multiarch-manifest-to-release DOCKER_MULTIARCH_MANIFEST=$(DOCKER_REPO)/$(BUILD_PATH):$(IMAGE_VERSION)
endif

.PHONY: sox-log-docker-sha
sox-log-docker-sha:
ifeq ($(CI),true)
ifneq ($(RELEASE_BRANCH),$(_empty))
	pip3 install confluent-ci-tools
	$(eval IMAGE_SHA := $(shell docker inspect --format="{{index .RepoDigests 0}}" "$(DEVPROD_NONPROD_GAR_REPO)/$(BUILD_PATH):$(IMAGE_VERSION)"))
	@echo "Reporting docker image information event for $(DEVPROD_NONPROD_GAR_REPO)/$(BUILD_PATH):$(IMAGE_VERSION), image sha: $(IMAGE_SHA)"
	ci-docker-image-semaphore-event --topic 'sox-sdlc-audit-automation' --version-tag $(IMAGE_VERSION) --sha256 $(IMAGE_SHA) --config-file $(HOME)/.sox-semaphore-build-info.ini
endif
endif

# For repos that only push to prod. If used, needs to be added to RELEASE_POSTCOMMIT after push-docker
.PHONY: sox-log-docker-sha-prod
sox-log-docker-sha-prod:
ifeq ($(CI),true)
ifneq ($(RELEASE_BRANCH),$(_empty))
	pip3 install confluent-ci-tools
	$(eval IMAGE_SHA := $(shell docker inspect --format="{{index .RepoDigests 0}}" "$(DOCKER_REPO)/$(BUILD_PATH):$(IMAGE_VERSION)"))
	@echo "Reporting docker image information event for $(DOCKER_REPO)/$(BUILD_PATH):$(IMAGE_VERSION), image sha: $(IMAGE_SHA)"
	ci-docker-image-semaphore-event --topic 'sox-sdlc-audit-automation' --version-tag $(IMAGE_VERSION) --sha256 $(IMAGE_SHA) --config-file $(HOME)/.sox-semaphore-build-info.ini
endif
endif

.PHONY: log-docker-image
log-docker-image:
ifeq ($(CI),true)
ifneq ($(RELEASE_BRANCH),$(_empty))
	$(eval IMAGE_DIGEST := $(shell docker inspect --format="{{index .RepoDigests 0}}" "$(DOCKER_REPO)/$(BUILD_PATH):$(IMAGE_VERSION)" | cut -d'@' -f2))
	@echo '{"images": [{"name": "$(IMAGE_NAME)", "repo": "$(DOCKER_REPO)/$(IMAGE_REPO)", "tag": "$(IMAGE_VERSION)", "digest": "$(IMAGE_DIGEST)"}]}'
endif
endif

.PHONY: clean-images
clean-images:
	docker images -q -f label=io.confluent.caas=true -f reference='*$(IMAGE_NAME)' | uniq | $(XARGS) docker rmi -f

.PHONY: clean-all
clean-all:
	docker images -q -f label=io.confluent.caas=true | uniq | $(XARGS) docker rmi -f

.PHONY: sign-image-index
sign-image-index:
	@curl -X POST \
		-w "%{http_code}\n" \
		$(IMAGE_SIGNING_URL) \
		-H "Authorization: Bearer ${SEMAPHORE_OIDC_TOKEN}" \
		-H "Content-Type: application/json" \
		-d '{"images": [{"uri": "$(DOCKER_REPO)/$(BUILD_PATH)@$(shell docker manifest push $(DOCKER_MULTIARCH_MANIFEST))"}]}'\
		| cat | sed '/^2/q ; /^\([1,3,4,5,6,7,8,9]\)/{s//Image signing error, please see: https:\/\/go\/image-signing-faq\n\1/ ; q1}'

.PHONY: sign-image
ifeq ($(DOCKER_RELEASE_MULTIARCH), true)
sign-image:
	$(MAKE) $(MAKE_ARGS) sign-image-arch ARCH=amd64 IMAGE_VERSION=$(IMAGE_VERSION)
	$(MAKE) $(MAKE_ARGS) sign-image-arch ARCH=arm64 IMAGE_VERSION=$(IMAGE_VERSION)
	$(MAKE) $(MAKE_ARGS) sign-image-index DOCKER_MULTIARCH_MANIFEST=$(DOCKER_REPO)/$(BUILD_PATH):$(IMAGE_VERSION)

.PHONY: sign-image-arch
sign-image-arch:
else
sign-image:
endif
ifeq ($(IMAGE_SIGNING_ENABLED),true)
ifneq ($(RELEASE_BRANCH),$(_empty))
	$(eval IMAGE_DIGEST := $(shell docker inspect --format="{{index .RepoDigests 0}}" "$(DOCKER_REPO)/$(BUILD_TAG)" | cut -d'@' -f2))
	@curl -X POST \
		-w "%{http_code}\n" \
		$(IMAGE_SIGNING_URL) \
		-H "Authorization: Bearer ${SEMAPHORE_OIDC_TOKEN}" \
		-H "Content-Type: application/json" \
		-d '{"images": [{"uri": "$(DOCKER_REPO)/$(BUILD_PATH)@$(IMAGE_DIGEST)"}]}' \
		| cat | sed '/^2/q ; /^\([1,3,4,5,6,7,8,9]\)/{s//Image signing error, please see: https:\/\/go\/image-signing-faq\n\1/ ; q1}'
endif
endif
