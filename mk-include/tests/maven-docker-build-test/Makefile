SERVICE_NAME := test-service
IMAGE_NAME := cc-$(SERVICE_NAME)
CHART_NAME := cc_test_service

HELM_PACKAGE_DIR := target/charts/package
RELEASE_NAME := $(CHART_NAME)
DOCKER_BUILD_OPTIONS += --build-arg ARTIFACT_ID=$(IMAGE_NAME)
DEPLOYER_DOWNSTREAM_DEPS := obs-helm
MVN := ./mvnw
CI_TEST := true
PUSH_DOCKER_OVERRIDE := $(shell echo skipping docker push)
GOPATH=$(go env GOPATH)
CI_BIN_OVERRIDE := ${GOPATH}/src/github.com/confluentinc/cc-mk-include/ci-bin

include ./mk-include/cc-begin.mk
include ./mk-include/cc-vault.mk
include ./mk-include/cc-semver.mk
include ./mk-include/cc-maven.mk
include ./mk-include/cc-docker.mk
include ./mk-include/cc-cpd.mk
include ./mk-include/cc-semaphore.mk
include ./mk-include/cc-helm.mk
include ./mk-include/cc-testbreak.mk
include ./mk-include/cc-end.mk

.PHONY: maven-docker-build-test
maven-docker-build-test:
	python3 -m venv maven-docker-build-test
	source maven-docker-build-test/bin/activate && \
	pip3 install \
	    pytest=="$(PYTEST_VERSION)" \
        pytest-cov \
	    structlog=="${STRUCTLOG_VERSION}" && \
	pytest test.py -s --log-level="${PYTEST_LOG_LEVEL}" \
	    --cov-report=xml --cov-report=html --cov-report=term --cov-report=annotate:textcov
