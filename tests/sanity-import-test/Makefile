SERVICE_NAME := test-service
IMAGE_NAME := cc-$(SERVICE_NAME)
CHART_NAME := cc_test_service
GO_BINS := github.com/confluentinc/cc-test-service/cmd/server=test-service

READ_CONFIG_CMD := echo

DEPLOYER_DOWNSTREAM_DEPS := obs-helm

RELEASE_PRECOMMIT := pre-release-check

CI_TEST := true

include ./mk-include/cc-begin.mk
include ./mk-include/cc-vault.mk
include ./mk-include/cc-semver.mk
include ./mk-include/cc-api.mk
include ./mk-include/cc-chrome.mk
include ./mk-include/cc-ci-metrics.mk
include ./mk-include/cc-db.mk
include ./mk-include/cc-deb.mk
include ./mk-include/cc-go.mk
include ./mk-include/cc-python.mk
include ./mk-include/cc-docker.mk
include ./mk-include/cc-docker-redhat.mk
include ./mk-include/cc-docker-ubi.mk
include ./mk-include/cc-cpd.mk
include ./mk-include/cc-helm.mk
include ./mk-include/cc-helmfile.mk
include ./mk-include/cc-launchdarkly.mk
include ./mk-include/cc-librdkafka.mk
include ./mk-include/cc-protoc.mk
include ./mk-include/cc-runscope.mk
include ./mk-include/cc-sops.mk
include ./mk-include/cc-spire.mk
include ./mk-include/cc-system-tests.mk
include ./mk-include/cc-telepresence.mk
include ./mk-include/cc-terraform.mk
include ./mk-include/cc-semaphore.mk
include ./mk-include/cc-sonarqube.mk
include ./mk-include/cc-testbreak.mk
include ./mk-include/cc-end.mk

GO_TEST_ARGS += -p=1

.PHONY: mk-include-sanity-import-test
mk-include-sanity-import-test:
	python3 -m venv mk-include-sanity-import-test
	source mk-include-sanity-import-test/bin/activate && \
	pip3 install \
	    pytest=="$(PYTEST_VERSION)" \
        pytest-cov \
	    structlog=="${STRUCTLOG_VERSION}" && \
	pytest test.py -s --log-level="${PYTEST_LOG_LEVEL}" \
	    --cov-report=xml --cov-report=html --cov-report=term --cov-report=annotate:textcov
