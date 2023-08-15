TEST_TARGETS += test-pact
INIT_CI_TARGETS += install-pact-cli

export PATH := $(PWD)/node_modules/.bin:$(PATH):$(PWD)/pact/bin
export PACT_DO_NOT_TRACK := true
# TODO: change this if required by DPTFI-330 or DPTFI-158
export PACT_BROKER_URL := https://pact.aws.stag.cpdev.cloud
PACT_TEST_DIR ?= $(PWD)/test/pact
PACTS_DIR ?= $(PWD)/test/pact/pacts
PACT_TESTS_ENABLED ?= true

# Installs various Pact CLIs and tools
# - ruby CLI
# - rust pact verifier CLI
# - pact plugin manager CLI
# - pact-go 2.0
# - pact-protobuf-plugin (via plugin manager CLI)
.PHONY: install-pact-cli
install-pact-cli:
	@$(MK_INCLUDE_BIN)/install-pact-tools.sh $(BIN_PATH)


.PHONY: test-pact
test-pact:
ifeq ($(PACT_TESTS_ENABLED),true)
	@echo "--- Running all Pact tests"
	GIT_COMMIT=$(GIT_COMMIT) BRANCH_NAME=$(BRANCH_NAME) go test -v -count=1 -tags=pact $(PACT_TEST_DIR)
else
	@echo "--- Skipping pact tests"
endif

.PHONY: pact-consumer
pact-consumer:
ifeq ($(PACT_TESTS_ENABLED),true)
	@echo "--- Running Consumer Pact tests "
	go test -v -count=1 -tags=pact.consumer $(PACT_TEST_DIR)
else
	@echo "--- Skipping pact tests"
endif

.PHONY: pact-provider
pact-provider:
ifeq ($(PACT_TESTS_ENABLED),true)
	@echo "--- Running Provider Pact tests"
	GIT_COMMIT=$(GIT_COMMIT) BRANCH_NAME=$(BRANCH_NAME) go test -v -count=1 -tags=pact.provider $(PACT_TEST_DIR)
else
	@echo "--- Skipping pact tests"
endif

.PHONY: pact-consumer-publish
pact-consumer-publish:
ifeq ($(CI),true)
ifeq ($(BRANCH_NAME),master)
	@echo "--- Publishing Consumer Pacts to the Pact Broker"
	./pact/bin/pact-broker publish $(PACTS_DIR) \
		--consumer-app-version $(GIT_COMMIT) \
		--branch $(BRANCH_NAME) \
		--broker-base-url $(PACT_BROKER_URL)
else
	@echo "--- not on master branch, skip publishing pacts"
endif
else
	@echo "--- not running in CI, skip publishing pacts"
endif

.PHONY: pact-require-environment
pact-require-environment:
# built-in `ifndef` is evaluated at parse-time
# so if PACT_RELEASE_ENVIRONMENT is defined in a different make file or simply below this target
# it would not see it.
# Shell `if` is evaluated at execution time, after all make files have been parsed,
# so doesn't matter if you define PACT_RELEASE_ENVIRONMENT before or after this target
	@if [ -z $(PACT_RELEASE_ENVIRONMENT) ]; then \
		echo "PACT_RELEASE_ENVIRONMENT is empty or not defined"; \
		exit 1; \
	fi

# requires PACT_RELEASE_ENVIRONMENT - must be provided by callers of pact-deploy
.PHONY: pact-deploy
pact-deploy: pact-require-environment
ifeq ($(CI),true)
	@echo "--- Pact Broker: record deployment of $(SERVICE_NAME) @ $(GIT_COMMIT) to $(PACT_RELEASE_ENVIRONMENT)"
	./pact/bin/pact-broker record-deployment \
		--pacticipant=$(SERVICE_NAME) \
		--version=$(GIT_COMMIT) \
		--environment=$(PACT_RELEASE_ENVIRONMENT) \
		--broker-base-url=$(PACT_BROKER_URL)
else
	@echo "--- Can only record deployments from CI"
	@echo "--- Exiting"
endif

# requires PACT_RELEASE_ENVIRONMENT - must be provided by callers of pact-can-i-deploy
.PHONY: pact-can-i-deploy
pact-can-i-deploy: pact-require-environment
	@echo "--- Pact Broker: can-i-deploy $(SERVICE_NAME) @ $(GIT_COMMIT) to $(PACT_RELEASE_ENVIRONMENT)"
	./pact/bin/pact-broker can-i-deploy \
		--pacticipant=$(SERVICE_NAME) \
		--version=$(GIT_COMMIT) \
		--to-environment=$(PACT_RELEASE_ENVIRONMENT) \
		--broker-base-url=$(PACT_BROKER_URL)
