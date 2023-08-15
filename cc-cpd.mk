# Default version to install, new enough to self update quickly
CPD_VERSION ?= baseline
CPD_UPDATE ?= true
GCLOUD_INSTALL ?= true

ifeq ($(GCLOUD_INSTALL),true)
INIT_CI_TARGETS += gcloud-install
endif
CLEAN_TARGETS += clean-cc-system-tests

# Set path for cpd binary
CPD_PATH := $(BIN_PATH)/cpd

POOL_TAG ?= random
POOL_NAME ?= ci

CPD_GKE = ""

# Create Arguments
CPD_CR_ARGS ?= --deploy=false --pool-name $(POOL_NAME)

# to check if we see `cc-` pattern
CHART_PREFIX := $(shell echo $(CHART_NAME) | head -c 3)

# system test variables
CC_SYSTEM_TESTS_URI ?= git@github.com:confluentinc/cc-system-tests.git
CC_SYSTEM_TESTS_REF ?= $(shell (test -f CC_SYSTEM_TESTS_VERSION && head -n 1 CC_SYSTEM_TESTS_VERSION) || echo master)
CREATE_KAFKA_CLUSTERS ?= false

.PHONY: show-cpd
## Show cpd vars
show-cpd:
	@echo "cpd version: $(CPD_VERSION)"
	@echo "cpd path: $(CPD_PATH)"
	@echo "cpd name: $(CPD_NAME)"
	@echo "cpd expire: $(CPD_EXPIRE)"
	@echo "cpd create args: $(CPD_CR_ARGS)"
	@echo "cpd running count: $(CPD_RUNNING_COUNT)"
	@echo "cc-system-tests run: $(RUN_SYSTEM_TESTS)"
	@echo "cc-system-tests uri: $(CC_SYSTEM_TESTS_URI)"
	@echo "cc-system-tests ref: $(CC_SYSTEM_TESTS_REF)"
	@echo "cc-system-tests delete: $(DELETE_CPD)"
	@echo "cc-system-tests create kafka clusters: $(CREATE_KAFKA_CLUSTERS)"

.PHONY: gcloud-install
gcloud-install:
ifeq ($(CI),true)
	gcloud config set project cloud-private-dev
	gcloud config set account semaphore@cloud-private-dev.iam.gserviceaccount.com
	gcloud auth activate-service-account --key-file ~/.config/gcloud/application_default_credentials.json
endif

.PHONY: cpd-install
# Install cpd if it's not installed
cpd-install:
	@if [ ! -f $(CPD_PATH) ]; then \
		echo "## Installing CPD binary"; \
		gsutil cp gs://cloud-confluent-bin/cpd/cpd-$(CPD_VERSION)-$(shell go env GOOS)-$(shell go env GOARCH) $(CPD_PATH); \
		chmod +x $(CPD_PATH); \
	fi

.PHONY: cpd-update
# Update cpd if needed, install if missing
cpd-update: cpd-install
ifeq ($(CPD_UPDATE),true)
	echo "## Updating CPD binary to latest";
	$(CPD_PATH) update --yes
endif

.PHONY: cpd-priv-create-if-missing
cpd-priv-create-if-missing:
	@if [ ! `kubectl config current-context` ]; then \
		echo "## Try to allocate a CPD from the ci pool"; \
		$(CPD_PATH) pool new $(CPD_CR_ARGS); \
		kubectl config current-context; \
	else \
		echo "Already allocated one CPD $(kubectl config current-context)"; \
	fi

# This is for CPD gating
CPD_GATING_VIA_HALYARD ?= true
CPD_HALYARD_DEPLOYER_ADDRESS ?= halyard-deployer.cpd.halyard.confluent.cloud:9090
CPD_HALYARD_RELEASE_ADDRESS ?= halyard-release.cpd.halyard.confluent.cloud:9090
CPD_HALYARD_RENDERER_ADDRESS ?= halyard-renderer.cpd.halyard.confluent.cloud:9090
CPD_HALCTL_ARGS := --vault-login-path auth/app/devel/login
CPD_HALCTL_ARGS += --vault-oidc-role halyard-devel
CPD_HALYARD_INSTALL_SERVICE_ENVS ?= $(SERVICE_NAME)=cpd
CPD_HALYARD_SERVICE_FILES ?= $(wildcard .halyard/*.yaml)

RELEASE_POSTCOMMIT += halyard-cpd-apply-services

.PHONY: halyard-cpd-apply-services
## Register the new version of the halyard spec with the halyard cpd instance, aka apply -f.
halyard-cpd-apply-services:
ifneq ($(CPD_HALYARD_SERVICE_FILES),)
	# When CI is running HAL_TMPDIR is a random file. Every time it's evaluated
	# it gives a random file. If we want to use the same random file, then we have
	# to save its output in a variable and pass that in to our makefile targets
	$(eval CPD_HAL_TMPDIR := $(HAL_TMPDIR))
	@echo "## Applying version with halyard CPD instance";
	HALYARD_DEPLOYER_ADDRESS=$(CPD_HALYARD_DEPLOYER_ADDRESS) \
	HALYARD_RELEASE_ADDRESS=$(CPD_HALYARD_RELEASE_ADDRESS) \
	HALYARD_RENDERER_ADDRESS=$(CPD_HALYARD_RENDERER_ADDRESS) \
	HALYARD_INSTALL_SERVICE_ENVS=$(CPD_HALYARD_INSTALL_SERVICE_ENVS) \
	HALYARD_SOURCE_VERSION=$(BUMPED_CHART_VERSION) \
	HALCTL_ARGS="$(CPD_HALCTL_ARGS)" \
	HAL_TMPDIR="$(CPD_HAL_TMPDIR)" \
	HALYARD_SERVICE_FILES="$(CPD_HALYARD_SERVICE_FILES)" \
	$(MAKE) $(MAKE_ARGS) halyard-apply-services
endif

.PHONY: halyard-set-default-version-cpd
## Set service default version on CPD
halyard-set-default-version-cpd:
	@echo "## Setting default version on Halyard CPD";
	HALYARD_DEPLOYER_ADDRESS=$(CPD_HALYARD_DEPLOYER_ADDRESS) \
	HALYARD_RELEASE_ADDRESS=$(CPD_HALYARD_RELEASE_ADDRESS) \
	HALYARD_RENDERER_ADDRESS=$(CPD_HALYARD_RENDERER_ADDRESS) \
	HALCTL_ARGS="$(CPD_HALCTL_ARGS)" \
	$(MAKE) $(MAKE_ARGS) halyard-set-default-version

.PHONY: halyard-find-helm-chart-version-cpd
# Find the helm chart version for prod using the internal halyard `installedVersion` from cpd yaml
# config
halyard-find-helm-chart-version-cpd:
ifeq ($(svc),)
	$(error svc must be set)
endif
ifeq ($(env),)
	$(error env must be set)
endif
ifeq ($(ver),)
	$(error ver must be set)
endif
	$(eval version := $(shell HALYARD_DEPLOYER_ADDRESS=$(CPD_HALYARD_DEPLOYER_ADDRESS) \
		HALYARD_RELEASE_ADDRESS=$(CPD_HALYARD_RELEASE_ADDRESS) \
		HALYARD_RENDERER_ADDRESS=$(CPD_HALYARD_RENDERER_ADDRESS) \
		HALCTL_ARGS="$(CPD_HALCTL_ARGS)" \
		env=$(env) \
		svc=$(svc) \
		ver=$(ver) \
		$(MAKE) $(MAKE_ARGS) halyard-find-helm-chart-version))
	@echo $(version)

.PHONY: find-halyard-version-from-helm-chart-cpd
# Find the internal halyard version for cpd given the helm chart version
find-halyard-version-from-helm-chart-cpd:
	$(eval version := $(shell HALYARD_DEPLOYER_ADDRESS=$(CPD_HALYARD_DEPLOYER_ADDRESS) \
		HALYARD_RELEASE_ADDRESS=$(CPD_HALYARD_RELEASE_ADDRESS) \
		HALYARD_RENDERER_ADDRESS=$(CPD_HALYARD_RENDERER_ADDRESS) \
		HALCTL_ARGS="$(CPD_HALCTL_ARGS)" \
		HALYARD_ENV_TO_DEPLOY=$(HALYARD_CPD_ENV) \
		helmChartVersion=$(helmChartVersion) \
		$(MAKE) $(MAKE_ARGS) halyard-find-version-from-helm-chart))
	@echo $(version)

.PHONY: find-halyard-default-version-cpd
find-halyard-default-version-cpd:
	HALYARD_DEPLOYER_ADDRESS=$(CPD_HALYARD_DEPLOYER_ADDRESS) \
	HALYARD_RELEASE_ADDRESS=$(CPD_HALYARD_RELEASE_ADDRESS) \
	HALYARD_RENDERER_ADDRESS=$(CPD_HALYARD_RENDERER_ADDRESS) \
	HALCTL_ARGS="$(CPD_HALCTL_ARGS)" \
	env="$(HALYARD_CPD_ENV_KEY)" \
	svc="$(svc)" \
	$(MAKE) $(MAKE_ARGS) halyard-find-default-version

.PHONY: cpd-deploy-local
## Deploy local chart to cpd cluster, only load images from dirty repo(GAR)
cpd-deploy-local: cpd-update helm-update-repo cpd-priv-create-if-missing
ifneq ($(wildcard .halyard/*.yaml),)
ifeq ($(CPD_GATING_VIA_HALYARD), true)
	# When CI is running HAL_TMPDIR is a random file. Every time it's evaluated
	# it gives a random file. If we want to use the same random file, then we have
	# to save its output in a variable and pass that in to our makefile targets
	$(eval CPD_HAL_TMPDIR := $(HAL_TMPDIR))
	@echo "## Updating halyard spec with dirty image";
	$(CPD_PATH) set-halyard-values \
		--set "image.tag=$(IMAGE_VERSION_NO_V)" \
		--set "image.repository=$(DEVPROD_NONPROD_GAR_REPO)/$(IMAGE_REPO)" \
		--file $(CPD_HALYARD_SERVICE_FILES)
	@echo "## Updating halyard with new halyard specs";
	HALYARD_DEPLOYER_ADDRESS=$(CPD_HALYARD_DEPLOYER_ADDRESS) \
	HALYARD_RELEASE_ADDRESS=$(CPD_HALYARD_RELEASE_ADDRESS) \
	HALYARD_RENDERER_ADDRESS=$(CPD_HALYARD_RENDERER_ADDRESS) \
	CPD_CLUSTER_ID=`kubectl config current-context` \
	HALYARD_INSTALL_SERVICE_ENVS=$(CPD_HALYARD_INSTALL_SERVICE_ENVS) \
	HALYARD_SOURCE_VERSION=$(CHART_VERSION) \
	HALCTL_ARGS="$(CPD_HALCTL_ARGS)" \
	HAL_TMPDIR="$(CPD_HAL_TMPDIR)" \
	$(MAKE) $(MAKE_ARGS) halyard-cpd-publish-dirty
	@echo "## Restore halyard spec";
	git reset $(wildcard .halyard/*.yaml)
	git checkout -f $(wildcard .halyard/*.yaml)
	@echo "## Deploying CPD cluster with halyard agent";
	$(CPD_PATH) priv dep --id `kubectl config current-context`
	@echo "## Inspect CPD cluster";
	$(CPD_PATH) debug --id `kubectl config current-context` --more || true
	@echo "## Install dirty service with halyard and check environment version";
	HALYARD_DEPLOYER_ADDRESS=$(CPD_HALYARD_DEPLOYER_ADDRESS) \
	HALYARD_RELEASE_ADDRESS=$(CPD_HALYARD_RELEASE_ADDRESS) \
	HALYARD_RENDERER_ADDRESS=$(CPD_HALYARD_RENDERER_ADDRESS) \
	CPD_CLUSTER_ID=`kubectl config current-context` \
	HALYARD_INSTALL_SERVICE_ENVS=$(CPD_HALYARD_INSTALL_SERVICE_ENVS) \
	HALYARD_SOURCE_VERSION=$(CHART_VERSION) \
	HALCTL_ARGS="$(CPD_HALCTL_ARGS)" \
	HAL_TMPDIR="$(CPD_HAL_TMPDIR)" \
	$(MAKE) $(MAKE_ARGS) halyard-cpd-install-dirty
endif
endif

.PHONY: cpd-destroy
## Clean up all cpd clusters
cpd-destroy:
	@if [ `kubectl config current-context 2> /dev/null` ]; then \
		echo "## Try to destroy CPD cluster (logs tailed)"; \
		$(CPD_PATH) pool free --id `kubectl config current-context` 2>&1 | tail -5; \
	fi

.cc-system-tests:
	git clone $(CC_SYSTEM_TESTS_URI) .cc-system-tests

.PHONY: checkout-cc-system-tests
checkout-cc-system-tests: .cc-system-tests
	@echo "## Checking out cc-system-tests"
	git -C ./.cc-system-tests fetch origin
	git -C ./.cc-system-tests checkout $(CC_SYSTEM_TESTS_REF)
	git -C ./.cc-system-tests merge origin/$(CC_SYSTEM_TESTS_REF)
	@echo "## cc-system-tests last commit:"
	@git -C ./.cc-system-tests log -n 1

define _newline


endef

#####################################
# Run tests on CPD
#####################################

ifndef TESTS_TO_RUN
# Currently TestAccountTestSuite are hardcoded as these seems to be the stable set of tests.
# These tests are run using go test -run, so this is an example on how to run different tests.
TESTS_TO_RUN ?= "TestFoobarTestSuite"
endif

.PHONY: system-tests-on-cpd
## Run cc-system tests
system-tests-on-cpd:
	@if git log -2 --format=%B | grep -iqF '[skip-cpd-gating]'; then \
		echo "system-tests-on-cpd is skipped"; \
	else \
		$(MAKE) $(MAKE_ARGS) _system-tests-on-cpd-helper; \
	fi

.PHONY: _system-tests-on-cpd-helper
_system-tests-on-cpd-helper:
	. $(MK_INCLUDE_BIN)/vault-setup
	$(MAKE) $(MAKE_ARGS) _run-cc-system-tests || ( $(CPD_PATH) debug --id `kubectl config current-context` --more; exit 1 )

CC_SYSTEM_TEST_CHECKOUT_DIR = ./.cc-system-tests
CC_SYSTEM_TEST_ENV_SECRETS = $(CC_SYSTEM_TEST_CHECKOUT_DIR)/.profile-with-secrets

# This is a hidden target, used only from the system-tests-on-cpd.
.PHONY: _run-cc-system-tests
_run-cc-system-tests: checkout-cc-system-tests cpd-deploy-local
	@echo "## Exporting CPD environment bash profile."
	set -o pipefail && $(CPD_PATH) priv testenv --id `kubectl config current-context` > $(CC_SYSTEM_TEST_ENV_SECRETS)
	@echo "## Running cc-system-tests's $(MAKE) init-env."
	source $(CC_SYSTEM_TEST_ENV_SECRETS) && CREATE_KAFKA_CLUSTERS=$(CREATE_KAFKA_CLUSTERS) $(MAKE) -C $(CC_SYSTEM_TEST_CHECKOUT_DIR) init-env
	@echo "## Show debug info about CPD cluster."
	$(CPD_PATH) debug --id `kubectl config current-context` --more || true
	@echo "## Running cc-system-tests tests."
	source $(CC_SYSTEM_TEST_ENV_SECRETS) && TEST_REPORT_FILE="$(BUILD_DIR)/ci-gating/TEST-report.xml" TESTS_TO_RUN='$(TESTS_TO_RUN)' $(MAKE) -C $(CC_SYSTEM_TEST_CHECKOUT_DIR) test


.PHONY: clean-cc-system-tests
## Clean up .cc-system-tests folder
clean-cc-system-tests:
	rm -rf $(CC_SYSTEM_TEST_CHECKOUT_DIR)
