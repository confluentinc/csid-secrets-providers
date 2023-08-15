# Note: you also need to include cc-cpd.mk as CPD is used as CLI to modify chart files.

CHART_NAME ?=
CHARTS_ROOT ?= charts
IMAGE_VERSION ?= 0.0.0

ARCH ?= amd64

HELM_VERSION ?= v3.10.1
HELM_TGZ := https://get.helm.sh/helm-$(HELM_VERSION)-linux-$(ARCH).tar.gz
HELM_BINARY := helm
HELM_ARTIFACTORY_PLUGIN_VERSION ?= 1.0.1
HELM_LOCAL_CHART_PLUGIN_VERSION ?= 0.1.0
HELM_REPO := https://confluent.jfrog.io/confluent/helm-cloud
INCLUDE_HELM_TARGETS ?= true
# Other services like CPD may use helm but do not build/test helm.
ifeq ($(INCLUDE_HELM_TARGETS),true)
INIT_CI_TARGETS += helm-setup-ci
BUILD_TARGETS += helm-package
TEST_TARGETS += helm-lint
CLEAN_TARGETS += helm-clean
RELEASE_PRECOMMIT += helm-set-bumped-version helm-update-floating-deps
RELEASE_MAKE_TARGETS += helm-release $(HELM_DOWNSTREAM_CHARTS)
endif

CHART_VERSION ?= $(VERSION_NO_V)
BUMPED_CHART_VERSION := $(BUMPED_CLEAN_VERSION)

CHART_NAMESPACE := $(CHART_NAME)-dev
CHART_RELEASE_NAME := $(CHART_NAME)-dev
CHART_LOCAL_PATH := $(CHARTS_ROOT)/$(CHART_NAME)

ifeq ($(HOST_OS),darwin)
HELM_REPO_CACHE := $(HOME)/Library/Caches/helm/repository
else
HELM_REPO_CACHE := $(HOME)/.cache/helm/repository
endif

# Include extra args for helm dep build
HELM_DEP_BUILD_EXTRA_ARGS ?=
# Target to use to push packaged Helm chart to Artifactory
HELM_PUSH_TARGET ?= helm-push-via-cpd

HELM_CHART_NAME_EXACT_MATCH ?= false

# requirements.lock - helm 2 / apiversion v1 charts.
# Chart.lock - helm 3 / apiversion v2 charts.
CHART_LOCK_FILE := $(wildcard $(CHART_LOCAL_PATH)/requirements.lock $(CHART_LOCAL_PATH)/Chart.lock)

# The main Chart.yaml file
# helm 3 / apiversion v2 charts contains dependencies aka pinned versions / version ranges.
CHART_YAML_FILE := $(CHART_LOCAL_PATH)/Chart.yaml

.PHONY: show-helm
## Show helm variables
show-helm:
	@echo "HELM_VERSION: $(HELM_VERSION)"
	@echo "CHART_NAME: $(CHART_NAME)"
	@echo "IMAGE_VERSION: $(IMAGE_VERSION)"
	@echo "CHART_VERSION: $(VERSION_NO_V)"
	@echo "CHART_URL: $(HELM_REPO)/$(CHART_NAME)/$(CHART_VERSION)"
	@echo "BUMPED_CHART_VERSION: $(BUMPED_CLEAN_VERSION)"
	@echo "HELM_DOWNSTREAM_CHARTS: $(HELM_DOWNSTREAM_CHARTS)"

.PHONY: helm-kube-config
helm-kube-config:
	chmod go-rw ~/.kube/config

.PHONY: helm-clean
helm-clean:
	@echo 💬 uninstalling chart release $(CHART_RELEASE_NAME) from namespace $(CHART_NAMESPACE)
	$(HELM_BINARY) uninstall --namespace $(CHART_NAMESPACE) $(CHART_RELEASE_NAME)

.PHONY: helm-lint
## Lint helm chart with values from $(CHART_LOCAL_PATH)/lint.yaml (if present)
helm-lint: helm-install-deps
	test -f $(CHART_LOCAL_PATH)/lint.yaml && VALUES="--values $(CHART_LOCAL_PATH)/lint.yaml" ;\
	echo "💬 running helm lint for chart and subchart (informational)"; \
	$(HELM_BINARY) lint --with-subcharts $(CHART_LOCAL_PATH) $$VALUES || true; \
	echo "💬 running helm lint again for chart only (validation)"; \
	$(HELM_BINARY) lint $(CHART_LOCAL_PATH) $$VALUES


.PHONY: helm-deploy-local
## Deploy helm to current kube context with values set to local.yaml
helm-deploy-local:
	@echo 💬 installing chart release $(CHART_RELEASE_NAME) into namespace $(CHART_NAMESPACE)
	# Note: do not use --debug as this leaks values to console or log, aka secrets.
	$(HELM_BINARY) upgrade --install $(CHART_RELEASE_NAME) $(CHART_LOCAL_PATH) \
	--namespace $(CHART_NAMESPACE) --create-namespace \
	--set namespace=$(CHART_NAMESPACE) \
	-f $(CHARTS_ROOT)/values/local.yaml \
	--set image.tag=$(IMAGE_VERSION) $(HELM_ARGS)

.PHONY: helm-set-bumped-version
helm-set-bumped-version:
	$(HELM_BINARY) plugin list | grep local-chart | grep -q "$(HELM_LOCAL_CHART_PLUGIN_VERSION)" || helm plugin install https://github.com/mbenabda/helm-local-chart-version --version "v$(HELM_LOCAL_CHART_PLUGIN_VERSION)"
	$(HELM_BINARY) local-chart-version set --chart $(CHART_LOCAL_PATH) --version $(BUMPED_CHART_VERSION) || true
	git add $(CHART_YAML_FILE) || true

.PHONY: helm-release-local
## Set the version to the current un-bumped version and package
helm-release-local: helm-release

$(HELM_REPO_CACHE)/stable-index.yaml:
	@echo 💬 helm repo stable repo missing, adding...
	@$(HELM_BINARY) repo add stable https://charts.helm.sh/stable

$(HELM_REPO_CACHE)/gloo-index.yaml:
	@echo 💬 helm repo gloo repo missing, adding...
	@$(HELM_BINARY) repo add gloo https://storage.googleapis.com/solo-public-helm

$(HELM_REPO_CACHE)/gloo-mesh-index.yaml:
	@echo 💬 helm repo gloo mesh repo missing, adding...
	@$(HELM_BINARY) repo add gloo-platform https://storage.googleapis.com/gloo-platform/helm-charts

.PHONY: helm-update-repo
helm-update-repo:  $(HELM_REPO_CACHE)/stable-index.yaml $(HELM_REPO_CACHE)/gloo-index.yaml $(HELM_REPO_CACHE)/gloo-mesh-index.yaml
	@echo 💬 updating index / cache of helm repos
	@$(HELM_BINARY) repo update

.PHONY: helm-install-deps
## Install subchart files in charts/ based on Chart.lock file
helm-install-deps: $(HELM_REPO_CACHE)/stable-index.yaml $(HELM_REPO_CACHE)/gloo-index.yaml $(HELM_REPO_CACHE)/gloo-mesh-index.yaml
	@echo 💬 building charts/ directory from Chart.lock
	$(HELM_BINARY) dep build $(CHART_LOCAL_PATH) $(HELM_DEP_BUILD_EXTRA_ARGS)

.PHONY: helm-update-floating-deps
## Update floating subchart versions that match the semantic version ranges in Chart.yaml
helm-update-floating-deps: $(HELM_REPO_CACHE)/stable-index.yaml $(HELM_REPO_CACHE)/gloo-index.yaml $(HELM_REPO_CACHE)/gloo-mesh-index.yaml
	@echo 💬 updating floating chart dependencies and updating lock file
	$(HELM_BINARY) dep update $(CHART_LOCAL_PATH)
	git add $(CHART_LOCK_FILE) || true

.PHONY: helm-pin-dependency-from-upstream
## Pin the upstream chart version in Chart.yaml
helm-pin-dependency-from-upstream:
	@echo 💬 updating chart dependency $(UPSTREAM_CHART) with pinned version $(UPSTREAM_VERSION)
	$(CPD_PATH) helm pin-dependency-version --chart $(CHART_LOCAL_PATH) --name $(UPSTREAM_CHART) --version $(UPSTREAM_VERSION)
	$(MAKE) $(MAKE_ARGS) helm-update-floating-deps
	git add $(CHART_YAML_FILE) $(CHART_LOCK_FILE) || true

.PHONY: helm-package helm-push-ecr helm-registry-login

helm-registry-login:
	@echo 💬 Log into ECR Helm registry
ifeq ($(CI),true)
	@aws ecr get-login-password --region us-west-2 | helm registry login --username AWS --password-stdin ${DEVPROD_PROD_ECR}
else
	@FORCE_NO_ALIAS=true GRANTED_QUIET=true assumego --exec "aws ecr get-login-password --region us-west-2" $(DEVPROD_PROD_ECR_PROFILE) | helm registry login --username AWS --password-stdin ${DEVPROD_PROD_ECR}
endif

helm-package: helm-registry-login helm-install-deps
	mkdir -p $(CHARTS_ROOT)/package
	rm -f $(CHARTS_ROOT)/package/$(CHART_NAME)-$(CHART_VERSION).tgz
	@echo 💬 build chart package $(CHART_NAME)-$(CHART_VERSION).tgz
	$(HELM_BINARY) package --version "$(CHART_VERSION)" $(CHART_LOCAL_PATH) -d $(CHARTS_ROOT)/package

helm-push-ecr:
	@if aws ecr list-images --repository-name ${DEVPROD_PROD_ECR_HELM_REPO_PREFIX}${CHART_NAME} --registry-id ${DEVPROD_PROD_AWS_ACCOUNT} --region us-west-2| jq '.imageIds[].imageTag | contains("${CHART_VERSION}")' | grep -q "true"; then\
		echo 💬 chart ${DEVPROD_PROD_ECR_HELM_REPO_PREFIX}$(CHART_NAME) with version $(CHART_VERSION) already exists;\
	else\
	    if [[ $(CHART_VERSION) == *"-dirty"* ]]; then\
			echo "WARNING! pushing a dirty chart version";\
			git status;\
	    fi;\
		echo 💬 pushing $(CHART_NAME)-$(CHART_VERSION) to ECR;\
		$(HELM_BINARY) push $(CHARTS_ROOT)/package/$(CHART_NAME)-$(CHART_VERSION).tgz oci://${DEVPROD_PROD_ECR}/${DEVPROD_PROD_ECR_HELM_REPO_PREFIX};\
	fi

.PHONY: helm-release
helm-release: helm-package helm-push-ecr

.PHONY: helm-setup-ci
helm-setup-ci:
	@echo 💬 checking / installing helm version $(HELM_VERSION)
	$(HELM_BINARY) version --short | grep -q $(HELM_VERSION) || \
		curl -s -L -o - $(HELM_TGZ) | tar -xz --strip-components=1 -C $(CI_BIN) linux-$(ARCH)/helm
	# if helm 2 is detected, run helm init
	@echo $(HELM_VERSION) | grep -Eq "^v2" && \
		$(HELM_BINARY) init --stable-repo-url "https://charts.helm.sh/stable" --client-only || true

.PHONY: helm-commit-deps
## Commit (and push) updated helm deps
helm-commit-deps:
	@echo 💬 commit and push changes to $(GIT_REMOTE_NAME) $(GIT_BRANCH_NAME)
	git diff --exit-code --name-status HEAD || \
		(git commit -m 'chore: $(UPSTREAM_CHART):$(UPSTREAM_VERSION) update chart deps' && \
		git push $(GIT_REMOTE_NAME) $(GIT_BRANCH_NAME))

.PHONY: helm-pin-dependency-in-downstream
## Update and deploy the deps
helm-pin-dependency-in-downstream:
	@echo 💬 updating downstream repo $(REPO_NAME) to pin $(CHART_NAME):$(CHART_VERSION)
	rm -rf $(REPO_NAME)
	git clone git@github.com:confluentinc/$(REPO_NAME).git $(REPO_NAME)
	$(MAKE) $(MAKE_ARGS) -C $(REPO_NAME) helm-pin-dependency-from-upstream helm-commit-deps \
		UPSTREAM_CHART=$(CHART_NAME) \
		UPSTREAM_VERSION=$(CHART_VERSION)
	@echo 💬 Successfully updated repo $(REPO_NAME) and pinned $(CHART_NAME):$(CHART_VERSION)

.PHONY: $(HELM_DOWNSTREAM_CHARTS)
## Update the downstream chart; pin the new chart version $(CHART_NAME):$(CHART_VERSION) as a dependency in $(HELM_DOWNSTREAM_CHARTS)
$(HELM_DOWNSTREAM_CHARTS):
ifeq ($(HOTFIX),true)
	@echo "💬 Skipping bumping downstream helm chart deps $@ on hotfix branch"
else ifeq ($(BUMP),major)
	@echo "💬 Skipping bumping downstream helm chart deps $@ with major version bump"
else
	@for i in $$(seq 1 3); do \
		echo "💬 Attempt to update downstream helm chart: $$i"; \
		$(MAKE) $(MAKE_ARGS) helm-pin-dependency-in-downstream REPO_NAME=$@ && break; \
	done
endif

.PHONY: test-helm-commands
## Test important helm commands, e.g. to validate a new helm version
test-helm-commands:
	$(MAKE) $(MAKE_ARGS) helm-registry-login
	$(MAKE) $(MAKE_ARGS) helm-update-repo
	$(MAKE) $(MAKE_ARGS) helm-install-deps
	$(MAKE) $(MAKE_ARGS) helm-update-floating-deps
	$(MAKE) $(MAKE_ARGS) helm-lint
	$(MAKE) $(MAKE_ARGS) helm-deploy-local
	$(MAKE) $(MAKE_ARGS) helm-clean
	$(MAKE) $(MAKE_ARGS) helm-package
