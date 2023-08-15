BUILD_TARGETS += mvn-install
CLEAN_TARGETS += mvn-clean
TEST_TARGETS += mvn-verify
RELEASE_PRECOMMIT += mvn-set-bumped-version
RELEASE_POSTCOMMIT += mvn-deploy

MAVEN_RETRY_COUNT = 3
MAVEN_RETRY_OPTS = -Dmaven.wagon.http.retryHandler.count=$(MAVEN_RETRY_COUNT)
MAVEN_ARGS ?= --no-transfer-progress
MAVEN_ADDITIONAL_ARGS ?=
MAVEN_ARGS += $(MAVEN_ADDITIONAL_ARGS)
MAVEN_NANO_VERSION ?= false
ifeq ($(CI),true)
MAVEN_LOCAL_CACHE ?= $(CI_BIN)/m2
MAVEN_ARGS += --batch-mode
# Put local maven repo inside CI_BIN to leverage caching done in cc-semaphore.mk
MAVEN_ARGS += -Dmaven.repo.local=$(MAVEN_LOCAL_CACHE) -Dmaven.artifact.threads=10
MAVEN_ARGS += $(MAVEN_RETRY_OPTS)
# enable CI profile for spotbugs, test-coverage, and dependency analysis
MAVEN_PROFILES += jenkins
endif

# Use predefine MVN or local `mvnw` if present in the repo, else fallback to globally installed `mvn`
ifeq ($(wildcard $(MVN)),)
MVN := $(GIT_ROOT)/mvnw
endif
ifeq ($(wildcard $(MVN)),)
MVN := mvn
endif
MVN += $(MAVEN_ARGS)
MVN += $(foreach profile,$(MAVEN_PROFILES),-P$(profile))

MAVEN_SKIP_CHECKS=-DskipTests=true \
        -Dcheckstyle.skip=true \
        -Dspotbugs.skip=true \
        -Djacoco.skip=true \
        -Ddependency-check.skip=true

MAVEN_INSTALL_OPTS ?= --update-snapshots $(MAVEN_SKIP_CHECKS)
MAVEN_INSTALL_ARGS = $(MAVEN_INSTALL_OPTS) install

MAVEN_DEPLOY_REPO_ID ?= confluent-codeartifact-internal
MAVEN_DEPLOY_REPO_NAME ?= maven-releases
MAVEN_DEPLOY_REPO_URL ?= https://confluent-519856050701.d.codeartifact.us-west-2.amazonaws.com/maven/$(MAVEN_DEPLOY_REPO_NAME)/

.PHONY: mvn-install
mvn-install:
ifneq ($(MAVEN_INSTALL_PROFILES),)
	$(MVN) $(foreach profile,$(MAVEN_INSTALL_PROFILES),-P$(profile)) $(MAVEN_INSTALL_ARGS)
else
	$(MVN) $(MAVEN_INSTALL_ARGS)
endif

ifeq ($(CI),true)
mvn-install: mvn-set-bumped-version
endif

.PHONY: mvn-verify
mvn-verify:
	$(MVN) $(MAVEN_VERIFY_OPTS) verify 

.PHONY: mvn-clean
mvn-clean:
	$(MVN) clean

# Alternatively, set <maven.deploy.skip>true</maven.deploy.skip> in your pom.xml to skip deployment
.PHONY: mvn-deploy
mvn-deploy:
	$(MVN) deploy $(MAVEN_SKIP_CHECKS) -DaltDeploymentRepository=$(MAVEN_DEPLOY_REPO_ID)::default::$(MAVEN_DEPLOY_REPO_URL) -DrepositoryId=$(MAVEN_DEPLOY_REPO_ID)

# Set the version in pom.xml to the bumped version
.PHONY: mvn-set-bumped-version
ifeq ($(MAVEN_NANO_VERSION),false)
mvn-set-bumped-version:
	$(MVN) versions:set \
		-DnewVersion=$(BUMPED_CLEAN_VERSION) \
		-DgenerateBackupPoms=false
	$(GIT) add --verbose $(shell find . -name pom.xml -maxdepth 2)
else
mvn-set-bumped-version: mvn-bump-nanoversion
endif

# Other projects have a superstitious dependency on docker-pull-base here
# instead of letting `docker build` just automatically pull the base image.
# If we start seeing build issues on MacOS we can resurrect this dependency.
# https://confluent.slack.com/archives/C6KU9M23A/p1559867903037100
#
#BASE_IMAGE := 519856050701.dkr.ecr.us-west-2.amazonaws.com/docker/prod/confluentinc/cc-base
#BASE_VERSION := v3.2.0
#mvn-docker-package: docker-pull-base
.PHONY: mvn-docker-package
mvn-docker-package:
	$(MVN) package \
	        $(MAVEN_SKIP_CHECKS) \
		--activate-profiles docker \
		-Ddocker.tag=$(IMAGE_VERSION) \
		-Ddocker.registry=$(DOCKER_REPO)/ \
		-DGIT_COMMIT=$(shell git describe --always --dirty) \
		-DBUILD_NUMBER=$(BUILD_NUMBER)
	docker tag $(DOCKER_REPO)/confluentinc/$(IMAGE_NAME):$(IMAGE_VERSION) \
		confluentinc/$(IMAGE_NAME):$(IMAGE_VERSION)

ifeq ($(CI),true)
	docker image save confluentinc/$(IMAGE_NAME):$(IMAGE_VERSION) | gzip | \
		artifact push project /dev/stdin -d docker/$(BRANCH_NAME)/$(IMAGE_VERSION).tgz --force
endif

.PHONY: show-maven
show-maven:
	@echo "MVN:                     $(MVN)"
	@echo "MAVEN_OPTS:              $(MAVEN_OPTS)"
	@echo "MAVEN_ARGS:              $(MAVEN_ARGS)"
	@echo "MAVEN_INSTALL_PROFILES:  $(MAVEN_INSTALL_PROFILES)"
	@echo "MAVEN_DEPLOY_REPO_URL: 	$(MAVEN_DEPLOY_REPO_URL)"

.PHONY: mvn-nanoversion-pip-deps
mvn-nanoversion-pip-deps:
	pip3 show confluent-ci-tools > /dev/null || pip3 install -U confluent-ci-tools

ifeq ($(CI),true)
.PHONY: mvn-bump-nanoversion
## use ci-tools to bump nanoversion
mvn-bump-nanoversion: mvn-nanoversion-pip-deps
	ci-update-version . $(SEMAPHORE_GIT_DIR) --no-update-dependency-versions --update-project-version

mvn-bump-dependency-nanoversion: mvn-nanoversion-pip-deps
## use ci-tools to update dependency nanoversion(mvn versions:use-latest-versions)
	ci-update-version . $(SEMAPHORE_GIT_DIR) --pinned-nano-versions --update-dependency-versions --no-update-project-version

.PHONY: mvn-push-nanoversion-tag
## use ci-tools to push the newest nanoversion tag
mvn-push-nanoversion-tag: mvn-nanoversion-pip-deps
	ci-push-tag . $(SEMAPHORE_GIT_DIR)

.PHONY: mvn-bump-nanoversion-and-push-tag
mvn-bump-nanoversion-and-push-tag: mvn-bump-nanoversion mvn-push-nanoversion-tag
endif
