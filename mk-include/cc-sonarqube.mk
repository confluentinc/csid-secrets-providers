
### Running the scanner:
# The scanner for sonarqube runs in a docker container that will mount your project as read only.
# It also can be ran in a secure mode (by default) that prevents the container from access any network outside of
# sonarqube itself.  It does this by proxying the connection to the sonarqube server with a socat container that
# runs in a public docker network, while the sonarqube scanner container runs in a private docker network.
#
# The scanner itself expects your sonar-project.properties to exist, which is created by the
# cc-service-bot sonarqube plugin.  Make sure your project exists in sonarqube before running
# at sonarqube.dp.confluent.io

SONAR_AUTH_TOKEN_VAULT_KV := token
SONAR_HOST := sonarqube.dp.confluent.io
SONAR_PORT := 9000
SONARQUBE_URL := http://$(SONAR_HOST):$(SONAR_PORT)
SONAR_SCANNER_ARGS := 
SONAR_PROJECT_NAME := $(SEMAPHORE_PROJECT_NAME)
SONAR_SCANNER_IMAGE := $(DEVPROD_PROD_ECR_REPO)/confluentinc/mirror/docker.io/sonarsource/sonar-scanner-cli:4.8.0
SONARQUBE_IP := $(shell nslookup $(SONAR_HOST) | grep 'Address: ' | head -n 1 | awk '{ print $$2 }')
# SOCAT is to isolate sonarqube from the semaphores ec2 network (or generally your network)
SOCAT_IMAGE := $(DEVPROD_PROD_ECR_REPO)/confluentinc/mirror/docker.io/alpine/socat:1.7.4.4
SCANNERWORK_KEY := $(shell echo "$(SEMAPHORE_PROJECT_NAME)-$(SEMAPHORE_JOB_NAME)-scannerwork" | tr ' ' '-')

RUN_SONAR_SCANNER_AFTER_TESTS ?= true


ifeq ($(RUN_SONAR_SCANNER_AFTER_TESTS),true)
ifeq ($(CI),true)
POST_TEST_TARGETS += sonar-scan
endif
endif

ifeq ($(SEMAPHORE_GIT_PR_NUMBER),)
	SONAR_SCANNER_ARGS += -Dsonar.branch.name=$(SEMAPHORE_GIT_BRANCH)
else
	SONAR_SCANNER_ARGS += -Dsonar.pullrequest.key=$(SEMAPHORE_GIT_PR_NUMBER)
	SONAR_SCANNER_ARGS += -Dsonar.pullrequest.branch=$(SEMAPHORE_GIT_PR_BRANCH)
	SONAR_SCANNER_ARGS += -Dsonar.pullrequest.base=$(SEMAPHORE_GIT_BRANCH)
endif

SONAR_SCANNER_CONTAINER_ARGS = \
	-e SONAR_HOST_URL="$(SONARQUBE_URL)" \
	-e SONAR_SCANNER_OPTS="$(SONAR_SCANNER_ARGS)" \
	-e SONAR_TOKEN="$(shell vault kv get -field $(SONAR_AUTH_TOKEN_VAULT_KV) 'v1/ci/kv/sonarqube/semaphore')" \
	--mount type=bind,source="$(shell pwd)",target="/usr/src",readonly \
	--mount type=bind,source="$(shell pwd)/.scannerwork",target="/usr/src/.scannerwork"

SONAR_RUN_WITH_PROXY := true
ifeq ($(SONAR_RUN_WITH_PROXY), true)
SONAR_CLEANUP_TARGETS := cleanup-sonar-proxy cleanup-sonar-docker-networks
SONAR_SCAN_TARGETS := create-sonar-docker-networks create-sonar-proxy run-sonar-scan-scanner
SONAR_SCANNER_CONTAINER_ARGS += --network sonar_isolated_network
SONAR_SCANNER_CONTAINER_ARGS += --add-host=$(SONAR_HOST):$$(docker inspect -f '{{.NetworkSettings.Networks.sonar_isolated_network.IPAddress}}' sonar-proxy)
else
SONAR_SCAN_TARGETS := run-sonar-scan-scanner
endif

.PHONY: print-ip
print-ip:
	echo $$(docker inspect -f '{{.NetworkSettings.Networks.sonar_isolated_network.IPAddress}}' sonar-proxy)

.PHONY: pull-sonar-scanner
pull-sonar-scanner:
	docker pull $(SONAR_SCANNER_IMAGE)
	docker pull $(SOCAT_IMAGE)

.PHONY: sonar-load-cache
sonar-load-cache:
ifeq ($(CI),true)
	@cache restore "'$(SCANNERWORK_KEY)'"
else
	@echo "not running on ci, not loading from cache"
endif

.PHONY: sonar-store-cache
sonar-store-cache:
ifeq ($(CI),true)
	@cache delete "'$(SCANNERWORK_KEY)'"
	@cache store "'$(SCANNERWORK_KEY)'" .scannerwork
else
	@echo "not running on ci, not storing to cache"
endif

.PHONY: sonar-scan
sonar-scan: sonar-load-cache run-sonar-scan sonar-store-cache

.PHONY: create-sonar-docker-networks
create-sonar-docker-networks:
	docker network create sonar_public_network
	docker network create --internal sonar_isolated_network

.PHONY: cleanup-sonar-docker-networks
cleanup-sonar-docker-networks:
	docker network rm sonar_public_network || true
	docker network rm sonar_isolated_network || true

.PHONY: create-sonar-proxy
create-sonar-proxy:
	docker run -d \
		--network sonar_public_network \
		--name sonar-proxy $(SOCAT_IMAGE) \
		tcp-listen:$(SONAR_PORT),reuseaddr,fork tcp:$(SONARQUBE_IP):$(SONAR_PORT)
	docker network connect sonar_isolated_network sonar-proxy

.PHONY: cleanup-sonar-proxy
cleanup-sonar-proxy:
	docker stop sonar-proxy || true
	docker rm sonar-proxy || true

# upload sonarqube data to sonarqube
.PHONY: run-sonar-scan-scanner
run-sonar-scan-scanner:
	@mkdir -p .scannerwork
	@echo "Running sonarqube scanner in docker container"
	@docker run $(SONAR_SCANNER_CONTAINER_ARGS) $(SONAR_SCANNER_IMAGE)

.PHONY: run-sonar-scan
run-sonar-scan:
	@make $(SONAR_SCAN_TARGETS) ;\
	STATUS=$$? ;\
	make $(SONAR_CLEANUP_TARGETS) ;\
	exit $$STATUS

.PHONY: sonarqube-gate-pip-deps
sonarqube-gate-pip-deps:
	pip3 show confluent-ci-tools > /dev/null || pip3 install -U confluent-ci-tools

.PHONY: sonar-gate
sonar-gate: sonarqube-gate-pip-deps
	@sonarqube-ci gate \
		$(SONAR_PROJECT_NAME) \
		--pr-id $(SEMAPHORE_GIT_PR_NUMBER) \
		--token $(shell vault kv get -field $(SONAR_AUTH_TOKEN_VAULT_KV) "v1/ci/kv/sonarqube/semaphore") \
		--host $(SONARQUBE_URL)
