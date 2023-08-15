# Addresses to halyard services
HALYARD_DEPLOYER_ADDRESS ?= halyard-deployer.prod.halyard.confluent.cloud:9090
HALYARD_RELEASE_ADDRESS ?= halyard-release.prod.halyard.confluent.cloud:9090
HALYARD_RENDERER_ADDRESS ?= halyard-renderer.prod.halyard.confluent.cloud:9090

# Addresses to halyard services in us-gov cloud
HALYARD_ADDRESS_US_GOV ?= prod.halyard.confluentgov-internal.com:443

# Determine which halyard services to auto bump source version
# List of halyard service files, default all.  All environments in these files will be bumped
HALYARD_SERVICE_FILES ?= $(wildcard .halyard/*.yaml)

# List of halyard service files with environments, defaults none.
# NOTE: This disables HALYARD_SERVICE_FILES, it's either full auto or full manual.
# NOTE: Apply always applies all files in HALYARD_SERVICE_FILES since it won't create new env
#       versions if there's nothing changed.
# Format: .halyard/service.yaml=env1 .halyard/service.yaml=env2 etc.
HALYARD_SERVICE_FILES_ENVS ?=

# Determine which halyard services in us-gov cloud to auto bump source version
# List of halyard service files, default all.  All environments in these files will be bumped
HALYARD_SERVICE_FILES_US_GOV ?= $(wildcard .halyard-us-gov/*.yaml)

# List of halyard service files with environments for us-gov cloud, defaults none.
# NOTE: This disables HALYARD_SERVICE_FILES_US_GOV, it's either full auto or full manual.
# NOTE: Apply always applies all files in HALYARD_SERVICE_FILES_US_GOV since it won't create new env
#       versions if there's nothing changed.
# Format: .halyard-us-gov/service.yaml=env1 .halyard-us-gov/service.yaml=env2 etc.
HALYARD_SERVICE_FILES_ENVS_US_GOV ?=

# Version to set source version to, defaults to current clean version without a v.
HALYARD_SOURCE_VERSION ?= $(BUMPED_CLEAN_VERSION)
# List of service/environments to automatically install on release, defaults none.
# Format: service=env service=env2 service2=env
HALYARD_INSTALL_SERVICE_ENVS ?=

# Cluster type to deploy services via halyard. Value must be be one of 'satellite' or 'mothership'
# If value not specified halyard will traverse thru all clusters which is very inefficient for mothersip services deployment.
HALYARD_INSTALL_CLUSTER_TYPE ?=

# List of service/environments to automatically associate with prod on release, defaults none.
# Format: service=env service=env2 service2=env
HALYARD_ASSOCIATE_SERVICE_ENVS ?=

# Controls whether or not halyard will wait for the agent to report that the service is RUNNNIG before declaring a successful installation
# - When "always halyard will wait
# - When "never", halyard will not wait
# - When unset, halyard will wait if only deploying to mothership, otherwise it will not wait
HALYARD_CHECK_AGENT_REPORTED_STATE ?=

# Sleep duration before retrying during the halyard deployment failure.
# DP-7152: To withstand the artifactory delays, lets add some delay before retry
DEFAULT_SLEEP_DURATION ?= 10 # chosen randomly to sleep for 60 sec with 6 retries before failing the build

# K8s cluster environment where deploy.sh targets. By default cluster_env takes value from halyard ENV value.
CLUSTER_ENV ?= ""

# Only create a tmpdir on CI
ifeq ($(CI),true)
# we need ?= to allow overridding HAL_TMPDIR for CPD gating
HAL_TMPDIR ?= $(shell mktemp -d 2>/dev/null || mktemp -d -t 'halyard')
GIT_SHA ?= $(SEMAPHORE_GIT_SHA)
GIT_REPO ?= $(SEMAPHORE_GIT_REPO_SLUG)
else
# when we aren't running CI, just put output in a temporary directory
HAL_TMPDIR ?= .halctl/tmp
GIT_SHA ?= ""
GIT_REPO ?= ""
endif
# we need := for immediate assignment rather than deferred.
HAL_TMPDIR := $(HAL_TMPDIR)

# Filter for semver git tag formats if SEMVER_TAGS_ONLY is true
GIT_DESCRIBE_MATCH := v[0-9]*.[0-9]*.[0-9]*
GIT_DESCRIBE_EXCLUDE := v*[^0-9.]!(-ce)!(-SNAPSHOT)*
ifeq ($(SEMVER_TAGS_ONLY),true)
GIT_DESCRIBE := git describe --contains --match "$(GIT_DESCRIBE_MATCH)" --exclude "$(GIT_DESCRIBE_EXCLUDE)"
else
GIT_DESCRIBE := git describe --contains
endif

# setup halctl cmd
HALYARD_VERSION ?= latest
HALCTL_ARGS ?=
HALYARD_IMAGE ?= $(DEVPROD_PROD_ECR_REPO)/confluentinc/halyard:$(HALYARD_VERSION)
_halctl_opts := --deployer-address $(HALYARD_DEPLOYER_ADDRESS)
_halctl_opts += --release-address $(HALYARD_RELEASE_ADDRESS)
_halctl_opts += --renderer-address $(HALYARD_RENDERER_ADDRESS)
_halctl_opts += $(HALCTL_ARGS)
_halctl_docker_opts := --user $(shell id -u):$(shell id -g) --rm -t
_halctl_docker_opts += -v $(PWD):/work -v $(HOME)/.halctl:/.halctl -w /work
ifeq ($(CI),true)
_halctl_docker_opts += -v $(HAL_TMPDIR):$(HAL_TMPDIR)
_halctl_docker_opts += --env-file ~/.halyard_secrets
else
_halctl_docker_opts += -e VAULT_TOKEN=$(shell cat $(HOME)/.vault-token)
endif
HALCTL ?= DOCKER_DEFAULT_PLATFORM=linux/amd64 docker run $(_halctl_docker_opts) $(HALYARD_IMAGE) $(_halctl_opts)

_halctl_opts_us_gov := --deployer-address $(HALYARD_ADDRESS_US_GOV)
_halctl_opts_us_gov += --release-address $(HALYARD_ADDRESS_US_GOV)
_halctl_opts_us_gov += --renderer-address $(HALYARD_ADDRESS_US_GOV)
_halctl_opts_us_gov += --vault-oidc-role halyard-prod-us-gov
_halctl_opts_us_gov += --vault-login-path auth/app/prod-us-gov/login
_halctl_opts_us_gov += $(HALCTL_ARGS)

HALCTL_US_GOV ?= docker run $(_halctl_docker_opts) $(HALYARD_IMAGE) $(_halctl_opts_us_gov)

# Allows override of batch size - Default to 100
HALYARD_BATCH_SIZE ?= 100

# YQ docker image. Inspired by cc-releases
# `user=root` is required to fix permission issues when updating the yaml file, see
# https://github.com/mikefarah/yq/blob/master/README.md#running-as-root
YQ ?= docker run --rm -i -v "${PWD}":/workdir --user root mikefarah/yq

_deploy_sh_options := --entrypoint /etc/halyard/scripts/deploy.sh
_deploy_sh_options += $(HALYARD_IMAGE)
_deploy_sh_options += -size $(HALYARD_BATCH_SIZE)
_deploy_sh_options += -apply

ifneq ($(HALYARD_CHECK_AGENT_REPORTED_STATE),)
_deploy_sh_options += -check-agent-reported-state $(HALYARD_CHECK_AGENT_REPORTED_STATE)
endif
# deploy.sh docker image. Inspired by cc-releases
DEPLOY_SH ?= docker run $(_halctl_docker_opts) $(_deploy_sh_options)

# variables that allow various makefile targets to be configurable.
#
# HALYARD_AUTO_DEPLOY_ENV => a synonym to HALYARD_INSTALL_SERVICE_ENVS. The reason why we want to define a new synonym is
# to avoid the failure mode where overloading results in unintended side effect due to HALYARD_INSTALL_SERVICE_ENVS being used in other makefile targets
HALYARD_AUTO_DEPLOY_ENV ?=# Defaults to empty str.

# The only Clusters where we want to auto deploy. Cluster IDs should be separated by comma.
HALYARD_AUTO_DEPLOY_CLUSTER_LIST ?=# Defaults to empty str

# HALYARD_STABLE_PREPROD_ENV => a synonym of stag in the current state of the world and in future for control plane, would be stag and for data plane
# would be devel owing to the split pre prod initiative.
# Unlike HALYARD_AUTO_DEPLOY_ENV, this variable is the name of a yaml file corresponding to the stable preprod env within .deployed-services folder.
# This contains contents similar to cc-releases yaml artifact. Developers who want to avoid building new docker images/helm charts are advised to
# use change_in semaphoreci target similar to https://github.com/confluentinc/cc-test-service/pull/52 and https://github.com/confluentinc/cc-spec-connect/pull/301
# Assumes by definition the file is called stag.yaml but the user is free to customize it for multiple targets emanating off .halyard
HALYARD_STABLE_PREPROD_ENV ?= stag.yaml

# The only Clusters where we want to deploy on pre prod. Cluster IDs should be separated by comma.
HALYARD_STABLE_PREPROD_CLUSTER_LIST ?=# Defaults to empty str

# HALYARD_PROD_ENV => Same as above. Except this offers a hook to customize the name prod.yaml and provide the option to define multiple service specs in one repo { monorepo }
HALYARD_PROD_ENV ?= prod.yaml

# The only Clusters where we want to deploy on prod. Cluster IDs should be separated by comma.
HALYARD_PROD_CLUSTER_LIST ?=# Defaults to empty str

# HALYARD_CPD_ENV => Offers a hook to customize the name cpd.yaml.
HALYARD_CPD_ENV ?= cpd.yaml
HALYARD_CPD_ENV_KEY ?= cpd

# Define a target specific variable that allows us to reuse the implementation for fetching and deploying stable_preprod and prod
HALYARD_ENV_TO_DEPLOY ?=# Empty variable.

# Empty variable that can be hooked into by cc-cpd.mk to set the path to the cpd.yaml
HALYARD_ENV_TO_SET_DEFAULT_VER ?=# Empty variable.

HALYARD_DEPLOYED_VERSIONS_DIR ?= .deployed-versions
# Deployed versions files of destination environments to auto promote a halyard version. Files
# should be separated by space, e.g. HALYARD_PROMOTE_DEST_DEPLOYED_VERSIONS="cpd.yaml devel.yaml"
HALYARD_PROMOTE_DEST_DEPLOYED_VERSIONS ?=# Defaults to empty str
# Deployed version of the source environment to auto promote a halyard version, e.g.,
# HALYARD_PROMOTE_SRC_DEPLOYED_VERSION=prod.yaml
HALYARD_PROMOTE_SRC_DEPLOYED_VERSION ?=# Defaults to empty str

INIT_CI_TARGETS += halyard-cache-image
RELEASE_PRECOMMIT += halyard-set-source-version
RELEASE_POSTCOMMIT += halyard-apply-services halyard-install-services

# An identifier to return with helm chart version so as to help with passing it between make
# targets
CHART_VERSION_IDENTIFIER = "chartVersion="
HALYARD_VERSION_IDENTIFIER = "halyardVersion="

.PHONY: show-halyard
## Show Halyard Variables
show-halyard:
	@echo "HALYARD_SERVICE_FILES:               $(HALYARD_SERVICE_FILES)"
	@echo "HALYARD_SERVICE_FILES_ENVS:          $(HALYARD_SERVICE_FILES_ENVS)"
	@echo "HALYARD_INSTALL_SERVICE_ENVS:        $(HALYARD_INSTALL_SERVICE_ENVS)"
	@echo "HALYARD_ASSOCIATE_SERVICE_ENVS:      $(HALYARD_ASSOCIATE_SERVICE_ENVS)"
	@echo "HALYARD_SERVICE_FILES_US_GOV:        $(HALYARD_SERVICE_FILES_US_GOV)"
	@echo "HALYARD_SERVICE_FILES_ENVS_US_GOV:   $(HALYARD_SERVICE_FILES_ENVS_US_GOV)"
	@echo "HALYARD_SOURCE_VERSION:              $(HALYARD_SOURCE_VERSION)"
	@echo "HALCTL:                              $(HALCTL)"
	@echo "HALCTL_US_GOV:                       $(HALCTL_US_GOV)"
	@echo "HALYARD_AUTO_DEPLOY_ENV:             $(HALYARD_AUTO_DEPLOY_ENV)"
	@echo "HALYARD_STABLE_PREPROD_ENV:          $(HALYARD_STABLE_PREPROD_ENV)"
	@echo "HALYARD_PROD_ENV:                    $(HALYARD_PROD_ENV)"
	@echo "HAL_TMPDIR:                          $(HAL_TMPDIR)"
	@echo "DEPLOY_SH:                           $(DEPLOY_SH)"
	@echo "YQ:                                  $(YQ)"


# target for caching the halyard docker image on semaphore
.PHONY: halyard-cache-image
halyard-cache-image:
	cache restore $(HALYARD_IMAGE)
	test ! -f halyard-image.tgz || docker load -i halyard-image.tgz
	mv halyard-image.tgz halyard-image-prev.tgz || echo dummy > halyard-image-prev.tgz
	docker pull $(HALYARD_IMAGE) 2>&1 | tee /tmp/cached-halyard-base.log
	cat /tmp/cached-halyard-base.log | grep -q "up to date" || echo "outdated" > /tmp/cached-halyard-base.log

	if [ "$$(cat /tmp/cached-halyard-base.log)" == "outdated" ]; then \
		set -o pipefail && docker save $(HALYARD_IMAGE) | gzip --no-name > halyard-image.tgz && \
		cache delete $(HALYARD_IMAGE) && cache store $(HALYARD_IMAGE) halyard-image.tgz; \
	fi
	rm -f halyard-image*.tgz

$(HOME)/.halctl:
	mkdir $(HOME)/.halctl

.PHONY: halctl
## Run halctl in the halyard docker image
halctl: $(HOME)/.halctl
	@$(HALCTL) $(HALCTL_ARGS)

.PHONY: halyard-set-source-version
ifeq ($(HALYARD_SERVICE_FILES_ENVS),)
halyard-set-source-version: $(HALYARD_SERVICE_FILES:%=set.%)
else
halyard-set-source-version: $(HALYARD_SERVICE_FILES_ENVS:%=set.%)
endif
ifeq ($(HALYARD_SERVICE_FILES_ENVS_US_GOV),)
halyard-set-source-version: $(HALYARD_SERVICE_FILES_US_GOV:%=set.%)
else
halyard-set-source-version: $(HALYARD_SERVICE_FILES_ENVS_US_GOV:%=set.%)
endif

.PHONY: $(HALYARD_SERVICE_FILES:%=set.%)
$(HALYARD_SERVICE_FILES:%=set.%): $(HOME)/.halctl
	$(HALCTL) release set-file-version -v $(HALYARD_SOURCE_VERSION) -f $(@:set.%=%) -c $(GIT_SHA) -r $(GIT_REPO)
	git add $(@:set.%=%)
	@$(eval env_path := $(shell dirname $(@:set.%=%))/envs/)
	@if [[ -d $(env_path) ]]; then \
		git add --all $(env_path); \
	fi;

.PHONY: $(HALYARD_SERVICE_FILES_ENVS:%=set.%)
$(HALYARD_SERVICE_FILES_ENVS:%=set.%): $(HOME)/.halctl
	@$(eval fpath := $(word 1,$(subst =, ,$(@:set.%=%))))
	@$(eval env := $(word 2,$(subst =, ,$(@:set.%=%))))
	$(HALCTL) release set-file-version -v $(HALYARD_SOURCE_VERSION) -f $(fpath) -e $(env) -c $(GIT_SHA) -r $(GIT_REPO)
	git add $(fpath)
	@$(eval env_path := $(shell dirname $(fpath))/envs/)
	@if [[ -d $(env_path) ]]; then \
		git add --all $(env_path); \
	fi;

.PHONY: $(HALYARD_SERVICE_FILES_US_GOV:%=set.%)
$(HALYARD_SERVICE_FILES_US_GOV:%=set.%): $(HOME)/.halctl
	$(HALCTL_US_GOV) release set-file-version -v $(HALYARD_SOURCE_VERSION) -f $(@:set.%=%) -c $(GIT_SHA) -r $(GIT_REPO)
	git add $(@:set.%=%)
	@$(eval env_path := $(shell dirname $(@:set.%=%))/envs/)
	@if [[ -d $(env_path) ]]; then \
		git add --all $(env_path); \
	fi;

.PHONY: $(HALYARD_SERVICE_FILES_ENVS_US_GOV:%=set.%)
$(HALYARD_SERVICE_FILES_ENVS:%=set.%): $(HOME)/.halctl
	@$(eval fpath := $(word 1,$(subst =, ,$(@:set.%=%))))
	@$(eval env := $(word 2,$(subst =, ,$(@:set.%=%))))
	$(HALCTL_US_GOV) release set-file-version -v $(HALYARD_SOURCE_VERSION) -f $(fpath) -e $(env) -c $(GIT_SHA) -r $(GIT_REPO)
	git add $(fpath)
	@$(eval env_path := $(shell dirname $(fpath))/envs/)
	@if [[ -d $(env_path) ]]; then \
		git add --all $(env_path); \
	fi;

.PHONY: halyard-apply-services
halyard-apply-services: $(HALYARD_SERVICE_FILES:%=apply.%)

.PHONY: $(HALYARD_SERVICE_FILES:%=apply.%)
$(HALYARD_SERVICE_FILES:%=apply.%): $(HOME)/.halctl
	$(HALCTL) release apply -f $(@:apply.%=%) --output-dir $(HAL_TMPDIR)

.PHONY: halyard-apply-services-us-gov
halyard-apply-services-us-gov: $(HALYARD_SERVICE_FILES_US_GOV:%=apply.%)

.PHONY: $(HALYARD_SERVICE_FILES_US_GOV:%=apply.%)
$(HALYARD_SERVICE_FILES_US_GOV:%=apply.%): $(HOME)/.halctl
	$(HALCTL_US_GOV) release apply -f $(@:apply.%=%) --output-dir $(HAL_TMPDIR)


.PHONY: halyard-associate-us-gov-version-with-prod
halyard-associate-us-gov-version-with-prod: $(HALYARD_ASSOCIATE_SERVICE_ENVS:%=associate.%)

.PHONY:$(HALYARD_ASSOCIATE_SERVICE_ENVS:%=associate.%)
$(HALYARD_ASSOCIATE_SERVICE_ENVS:%=associate.%): $(HOME)/.halctl
	$(eval svc := $(word 1,$(subst =, ,$(@:associate.%=%))))
	$(eval us-gov-env := $(word 2,$(subst =, ,$(@:associate.%=%))))
	$(eval prod_latest_version := $(HALCTL) release svc env ver get-latest-version $(svc) prod)
	$(eval prod_us_gov_latest_version := $(HALCTL_US_GOV) release svc env ver get-latest-version $(svc) $(us-gov-env))
	$(HALCTL) release svc relate-environment-versions $(svc) --env-ver prod=$(prod_latest_version) --env-ver $(us-gov-env)=$(prod_us_gov_latest_version) --referenceEnv prod

.PHONY: halyard-get-associated-us-gov-version
halyard-get-associated-us-gov-version: $(HALYARD_ASSOCIATE_SERVICE_ENVS:%=get-associated.%)

.PHONY:$(HALYARD_ASSOCIATE_SERVICE_ENVS:%=get-associated.%)
$(HALYARD_ASSOCIATE_SERVICE_ENVS:%=get-associated.%): $(HOME)/.halctl
	$(eval svc := $(word 1,$(subst =, ,$(@:get-associated.%=%))))
	$(eval us-gov-env := $(word 2,$(subst =, ,$(@:get-associated.%=%))))
	$(eval prod_latest_version := $(HALCTL) release svc env ver get-latest-version $(svc) prod)
	$(HALCTL) release svc env ver get-related-version-for-env $(svc) prod $(prod_latest_version) --forEnv $(us-gov-env)

halyard-apply-services-us-gov: $(HALYARD_SERVICE_FILES_US_GOV:%=apply.%)

cc-releases:
	git clone git@github.com:confluentinc/cc-releases.git

.PHONY: update-cc-releases
update-cc-releases:
	git -C cc-releases checkout master
	git -C cc-releases pull

commit-cc-releases:
	git -C cc-releases diff --exit-code --cached --name-status || \
	(git -C cc-releases commit -m "chore: auto update" && \
	git -C cc-releases push)
	rm -rf cc-releases

.PHONY: halyard-list-service-version
halyard-list-service-version: $(HALYARD_INSTALL_SERVICE_ENVS:%=list.%)

# Retrieve the current running halyard version, for the service/env specified in 'HALYARD_INSTALL_SERVICE_ENVS'.
# The service source version is deteremined by 'git describe --contains', and the retrieved halyard version is saved into $(HAL_TMPDIR)/$(svc)/$(env)
# This target can be used together with halyard-install-services to install service version corresponding to a specific commit.
# E.g. `HALYARD_INSTALL_SERVICE_ENVS=cc-pipeline-service=stag make halyard-list-service-version halyard-install-services` during CI will install the
# current in-release cc-pipeline-service version onto stag environment
.PHONY: $(HALYARD_INSTALL_SERVICE_ENVS:%=list.%)
$(HALYARD_INSTALL_SERVICE_ENVS:%=list.%): $(HOME)/.halctl
	$(eval svc := $(word 1,$(subst =, ,$(@:list.%=%))))
	$(eval env := $(word 2,$(subst =, ,$(@:list.%=%))))
	$(eval src_ver := $(shell git rev-parse --is-inside-work-tree > /dev/null && $(GIT_DESCRIBE) | grep '^v[0-9]\+.[0-9]\+.[0-9]\+\(~1\)\?$$' | cut -d'~' -f1 | cut -c 2-) )
	@echo "Found source version: $(src_ver)"
	@[[ ! -z "$(src_ver)" ]] || exit 1
	$(eval halyard_ver := $(shell set -o pipefail && $(HALCTL) release service env ver list $(svc) $(env) | grep $(src_ver) | tr -s ' ' | cut -d ' ' -f 2 | tail -1))
	@echo "Found halyard version: $(halyard_ver)"
	@[[ ! -z "$(halyard_ver)" ]] || exit 1
	@mkdir -p $(HAL_TMPDIR)/$(svc)
	echo $(halyard_ver) >> $(HAL_TMPDIR)/$(svc)/$(env)

.PHONY: halyard-wait-service-version
halyard-wait-service-version: halyard-list-service-version $(HALYARD_INSTALL_SERVICE_ENVS:%=wait.%)

# Wait for the source version to be installed, for the service/env specified in 'HALYARD_INSTALL_SERVICE_ENVS'.
# The service source version is deteremined by 'git describe --contains', representing the new version tag commited after a successful 'release-ci'
# If the source version is identified, it periodically queries halyard to wait for the version being succesffully installed on all relevant k8s clusters,
# otherwise it fails after a timeout, currently default to 20 iteration with 30 seconds interval, equals to 10 mins.
# E.g. `HALYARD_INSTALL_SERVICE_ENVS=cc-pipeline-service=devel make halyard-wait-service-version` will wait for current in-release verion to be installed on devel.
.PHONY: $(HALYARD_INSTALL_SERVICE_ENVS:%=wait.%)
$(HALYARD_INSTALL_SERVICE_ENVS:%=wait.%): $(HOME)/.halctl
	$(eval svc := $(word 1,$(subst =, ,$(@:wait.%=%))))
	$(eval env := $(word 2,$(subst =, ,$(@:wait.%=%))))
	$(eval halyard_ver := $(shell cat $(HAL_TMPDIR)/$(svc)/$(env)))
	@LOOP_COUNT=0; LOOP_TOTAL=20; LOOP_INTERVAL=30; \
	until [ $$LOOP_COUNT -eq $$LOOP_TOTAL ] || (echo "waiting halyard version $(halyard_ver) to be installed..." && $(HALCTL) release service env ver get $(svc) $(env) $(halyard_ver) -o json | jq -r .installStatus[].status 2>&1 | grep -v DONE | wc -l | tr -d ' ' | grep '^0$$'); \
	do $(HALCTL) release service env ver get $(svc) $(env) $(halyard_ver) -o json | jq -r .installStatus; (( LOOP_COUNT=LOOP_COUNT+1 )); [ $$LOOP_COUNT -lt $$LOOP_TOTAL ] && echo "still waiting..." && sleep $$LOOP_INTERVAL; done; \
	[ $$LOOP_COUNT -lt $$LOOP_TOTAL ] || (echo "Time out on waiting for version to be installed..." && exit 1)
	@echo "Halyard version $(halyard_ver) is installed"

.PHONY: halyard-install-services
halyard-install-services: cc-releases update-cc-releases $(HALYARD_INSTALL_SERVICE_ENVS:%=install.%) commit-cc-releases

.PHONY: $(HALYARD_INSTALL_SERVICE_ENVS:%=install.%)
$(HALYARD_INSTALL_SERVICE_ENVS:%=install.%): $(HOME)/.halctl
	$(eval svc := $(word 1,$(subst =, ,$(@:install.%=%))))
	$(eval env := $(word 2,$(subst =, ,$(@:install.%=%))))
	$(eval ver := $(shell cat $(HAL_TMPDIR)/$(svc)/$(env)))
	$(HALCTL) release set-file-install-version -v $(ver) -f cc-releases/services/$(svc)/$(env).yaml
	git -C cc-releases add services/$(svc)/$(env).yaml

.PHONY: halyard-cpd-publish-dirty
halyard-cpd-publish-dirty: halyard-set-source-version halyard-apply-services

.PHONY: halyard-cpd-install-dirty
halyard-cpd-install-dirty: $(HALYARD_INSTALL_SERVICE_ENVS:%=cpd.%)

.PHONY: $(HALYARD_INSTALL_SERVICE_ENVS:%=cpd.%)
$(HALYARD_INSTALL_SERVICE_ENVS:%=cpd.%): $(HOME)/.halctl
	@echo "## Ensure the cluster is healthy. Verify the health of all services used to provision a pkc by system tests";
	$(HALCTL) release cluster wait-until-healthy --cluster-id $(CPD_CLUSTER_ID) --services "cc-auth-service,cc-billing-worker,cc-fe,cc-flow-service,cc-gateway-service,cc-marketplace-service,cc-org-service,cc-scheduler-service,mcm-orchestrator,mothership-kafka,ratelimit,spec-kafka,support-service,sync-service" --wait 20m
	@echo "## Installing service in CPD cluster with halyard ⏳⏳⌛️";
	$(eval svc := $(word 1,$(subst =, ,$(@:cpd.%=%))))
	$(eval env := $(word 2,$(subst =, ,$(@:cpd.%=%))))
	@if [ ! -d $(HAL_TMPDIR)/$(svc) ]; then \
		echo "Service name $(svc) is incorrect. By default, SERVICE_NAME in Makefile is used. Pass the correct one by overriding CPD_HALYARD_INSTALL_SERVICE_ENVS"; \
		exit 1; \
	fi
	$(eval ver := $(shell cat $(HAL_TMPDIR)/$(svc)/$(env)))
	$(HALCTL) release service environment version install $(svc) $(env) $(ver) -c $(CPD_CLUSTER_ID)
	@echo "## Checking service status in halyard";
	$(HALCTL) release cluster wait-until-healthy --cluster-id $(CPD_CLUSTER_ID) --services "$(svc)" --wait 15m

.PHONY: halyard-deploy-service
halyard-deploy-service: $(HOME)/.halctl
ifeq ($(HALYARD_INSTALL_CLUSTER_TYPE), )
	@echo "deploy to all clusters, excluding vip clusters"
	$(DEPLOY_SH) -sleep $(sleep) -service $(svc) -env $(env) -cluster-env $(CLUSTER_ENV) -version $(ver)
	@svc=$(svc) env=$(env) ver=$(ver) sleep=$(sleep) $(MAKE) $(MAKE_ARGS) halyard-deploy-service-vip
else ifeq ($(HALYARD_INSTALL_CLUSTER_TYPE), "satellite")
	@echo "deploy to satellite clusters, excluding vip clusters"
	$(DEPLOY_SH) -sleep $(sleep) -service $(svc) -env $(env) -cluster-env $(CLUSTER_ENV) -version $(ver) -cluster-type satellite
	@svc=$(svc) env=$(env) ver=$(ver) sleep=$(sleep) $(MAKE) $(MAKE_ARGS) halyard-deploy-service-vip
else ifeq ($(HALYARD_INSTALL_CLUSTER_TYPE), "mothership")
	@echo "deploy to mothership clusters"
	$(DEPLOY_SH) -sleep $(sleep) -service $(svc) -env $(env) -cluster-env $(CLUSTER_ENV) -version $(ver) -cluster-type mothership
else
	@echo "Invalid cluster type $(HALYARD_INSTALL_CLUSTER_TYPE)"
endif

.PHONY: halyard-deploy-service-vip
halyard-deploy-service-vip: $(HOME)/.halctl
ifeq ($(env),prod)
	@echo "deploy to vip clusters"
	$(DEPLOY_SH) -sleep $(sleep) -service $(svc) -env $(env) -cluster-env $(CLUSTER_ENV) -version $(ver) -vip
endif

# these repo operations are needed when working with other branches: https://docs.semaphoreci.com/reference/toolbox-reference/#shallow-clone
.PHONY: unshallow-git-repo
unshallow-git-repo:
	$(eval isShallowRepo := $(shell $(GIT) rev-parse --is-shallow-repository))
	@if [[ "$(isShallowRepo)" == "true" ]]; then \
		$(GIT) fetch --unshallow --quiet; \
		$(GIT) config remote.$(GIT_REMOTE_NAME).fetch '+refs/heads/*:refs/remotes/$(GIT_REMOTE_NAME)/*'; \
		$(GIT) fetch --all --quiet; \
	fi

.PHONY: halyard-auto-deploy-service
halyard-auto-deploy-service: $(HOME)/.halctl
	$(eval localSvc := $(word 1,$(subst =, ,$(HALYARD_AUTO_DEPLOY_ENV))))
	$(eval localEnv := $(word 2,$(subst =, ,$(HALYARD_AUTO_DEPLOY_ENV))))
	$(eval halyard_ver := $(shell set -o pipefail && $(HALCTL) release service env ver list $(localSvc) $(localEnv) -ojson | jq -r '.[] | .version + " " +.sourceVersion' | grep -E '^[0-9]+ [0-9]+\.[0-9]+\.[0-9]+$$' | cut -d ' ' -f 1 | sort -n | tail -n 1))
	@if [ -z $(HALYARD_AUTO_DEPLOY_CLUSTER_LIST) ]; then \
		echo "Going to deploy $(localSvc) $(localEnv) $(halyard_ver)"; \
		svc=$(localSvc) env=$(localEnv) ver=$(halyard_ver) sleep=$(DEFAULT_SLEEP_DURATION) $(MAKE) $(MAKE_ARGS) halyard-deploy-service; \
	else \
 		echo "Going to deploy $(localSvc) $(localEnv) $(halyard_ver) on clusters $(HALYARD_AUTO_DEPLOY_CLUSTER_LIST)"; \
		svc=$(localSvc) env=$(localEnv) ver=$(halyard_ver) cluster=$(HALYARD_AUTO_DEPLOY_CLUSTER_LIST) $(MAKE) $(MAKE_ARGS) halyard-targeted-deploy; \
	fi;

.PHONY: halyard-deploy-stable-preprod
halyard-deploy-stable-preprod:
	HALYARD_ENV_TO_DEPLOY=$(HALYARD_STABLE_PREPROD_ENV) HALYARD_CLUSTER_TO_DEPLOY=$(HALYARD_STABLE_PREPROD_CLUSTER_LIST) $(MAKE) $(MAKE_ARGS) halyard-deploy-service-from-yaml-artifact

.PHONY: halyard-deploy-prod
halyard-deploy-prod:
	HALYARD_ENV_TO_DEPLOY=$(HALYARD_PROD_ENV) HALYARD_CLUSTER_TO_DEPLOY=$(HALYARD_PROD_CLUSTER_LIST) $(MAKE) $(MAKE_ARGS) halyard-deploy-service-from-yaml-artifact

.PHONY: halyard-deploy-service-from-yaml-artifact
halyard-deploy-service-from-yaml-artifact: unshallow-git-repo
ifneq ($(CI),true)
	@echo "Cannot deploy the contents of $(HALYARD_ENV_TO_DEPLOY) outside of PR'd CI Jobs"
	exit 1
endif
	$(eval localSvc := $(shell cat $(HALYARD_DEPLOYED_VERSIONS_DIR)/$(HALYARD_ENV_TO_DEPLOY) | $(YQ) eval '.data.service' -))
	$(eval localEnv := $(shell cat $(HALYARD_DEPLOYED_VERSIONS_DIR)/$(HALYARD_ENV_TO_DEPLOY) | $(YQ) eval '.data.environment' -))
	$(eval localVer := $(shell cat $(HALYARD_DEPLOYED_VERSIONS_DIR)/$(HALYARD_ENV_TO_DEPLOY) | $(YQ) eval '.data.installedVersion' -))
	@ $(GIT) fetch $(GIT_REMOTE_NAME) $(MASTER_BRANCH)
	$(eval masterVer := $(shell $(GIT) show $(GIT_REMOTE_NAME)/$(MASTER_BRANCH):$(HALYARD_DEPLOYED_VERSIONS_DIR)/$(HALYARD_ENV_TO_DEPLOY) | $(YQ) eval '.data.installedVersion // ""' -))
	@if [[ -z "$(localVer)" ]]; then \
		echo "$(HALYARD_ENV_TO_DEPLOY) has empty InstalledVersion. Nothing to deploy. $(localSvc) $(localEnv) $(localVer)"; \
	elif [[ "$(localVer)" != "$(masterVer)" ]]; then \
		echo "Only the latest version of the deployment file can be deployed. This commit's deployed version, $(HALYARD_DEPLOYED_VERSIONS_DIR)/$(HALYARD_ENV_TO_DEPLOY):$(localVer), is different from master's version, $(masterVer). Aborting the Halyard deployment."; \
		exit 1; \
	elif [[ -z "$(HALYARD_CLUSTER_TO_DEPLOY)" ]]; then \
		echo "Going to deploy $(localSvc) $(localEnv) $(localVer)"; \
		svc=$(localSvc) env=$(localEnv) ver=$(localVer) sleep=$(DEFAULT_SLEEP_DURATION) $(MAKE) $(MAKE_ARGS) halyard-deploy-service; \
	else \
 		echo "Going to deploy $(localSvc) $(localEnv) $(localVer) on clusters $(HALYARD_ENV_TO_DEPLOY)"; \
		svc=$(localSvc) env=$(localEnv) ver=$(localVer) cluster=$(HALYARD_CLUSTER_TO_DEPLOY) $(MAKE) $(MAKE_ARGS) halyard-targeted-deploy; \
	fi;

.PHONY: halyard-targeted-deploy
halyard-targeted-deploy: $(HOME)/.halctl
	@echo "Deploy $(svc) version $(ver) to the $(env) cluster(s) $(cluster)"
	$(DEPLOY_SH) -service $(svc) -env $(env) -cluster-env $(CLUSTER_ENV) -version $(ver) -target-clusters $(cluster)

.PHONY: halyard-deploy-cpd
halyard-deploy-cpd:
	$(MAKE) $(MAKE_ARGS) halyard-set-default-version-cpd

.PHONY: halyard-set-default-version
halyard-set-default-version: $(HOME)/.halctl
	$(eval localSvc := $(shell cat $(HALYARD_DEPLOYED_VERSIONS_DIR)/$(HALYARD_ENV_TO_SET_DEFAULT_VER) | $(YQ) eval '.data.service' -))
	$(eval localEnv := $(shell cat $(HALYARD_DEPLOYED_VERSIONS_DIR)/$(HALYARD_ENV_TO_SET_DEFAULT_VER) | $(YQ) eval '.data.environment' -))
	$(eval localVer := $(shell cat $(HALYARD_DEPLOYED_VERSIONS_DIR)/$(HALYARD_ENV_TO_SET_DEFAULT_VER) | $(YQ) eval '.data.installedVersion' -))
	@if [ ! -z $(localVer) ]; then \
		echo "Going to set $(localSvc) $(localVer) as default version on $(localEnv) "; \
		$(HALCTL) release service environment version set-default $(localSvc) $(localEnv) $(localVer); \
	else \
		echo "$(HALYARD_DEPLOYED_VERSIONS_DIR)/$(HALYARD_ENV_TO_SET_DEFAULT_VER) has empty InstalledVersion. Nothing to set as default version for $(localSvc) on $(localEnv)"; \
	fi;

# Parse the chart version after the pattern `chartVersion=`.
# $(call parse-chart-version,"chartVersion=1.1.1")
parse-chart-version = $(shell echo $(1) | grep -o "$(CHART_VERSION_IDENTIFIER)\S*" | cut -d "=" -f2)
parse-halyard-version = $(shell echo $(1) | grep -o "$(HALYARD_VERSION_IDENTIFIER)\S*" | cut -d "=" -f2)
parse-service-from-yaml = $(shell cat $(1) | $(YQ) eval '.data.service' -)
parse-environment-from-yaml = $(shell cat $(1) | $(YQ) eval '.data.environment' -)
parse-installed-version-from-yaml = $(shell cat $(1) | $(YQ) eval '.data.installedVersion' -)

.PHONY: halyard-find-helm-chart-version
# Find the helm chart version using the internal halyard `installedVersion` from config file
# NOTE: Since the return value is determined by what's being echo-ed, we add a pattern
# `chartVersion=` to the helm chart version. The caller can then use the function
# `parse-chart-version` to get the associated helm chart version.
halyard-find-helm-chart-version: $(HOME)/.halctl
ifeq ($(svc),)
	$(error svc must be set)
endif
ifeq ($(env),)
	$(error env must be set)
endif
ifeq ($(ver),)
	$(error ver must be set)
endif
	$(eval version := $(shell $(HALCTL) release service environment version get $(svc) $(env) $(ver) -o json | jq .sourceVersion))
	@echo $(CHART_VERSION_IDENTIFIER)$(version)

.PHONY: halyard-find-helm-chart-version-%
# Find the helm chart version using the internal halyard `installedVersion` from the given deployed
# version yaml supplied as a wildcard. To find the version corresponding to
# .deployed-versions/cpd.yaml, use `make halyard-find-helm-chart-version-cpd.yaml`
halyard-find-helm-chart-version-%:
	$(eval halyardDeployedVersion := $*)
ifeq ($(svc),)
	$(eval svc := $(call parse-service-from-yaml,$(HALYARD_DEPLOYED_VERSIONS_DIR)/$(halyardDeployedVersion)))
endif
ifeq ($(env),)
	$(eval env := $(call parse-environment-from-yaml,$(HALYARD_DEPLOYED_VERSIONS_DIR)/$(halyardDeployedVersion)))
	@if [ -z "$(env)" ]; then \
		echo "environment not found in $(halyardDeployedVersion)"; \
		exit 1; \
	fi
endif
ifeq ($(ver),)
	$(eval ver := $(call parse-installed-version-from-yaml,$(HALYARD_DEPLOYED_VERSIONS_DIR)/$(halyardDeployedVersion)))
endif
	@if [ "$(env)" == "$(HALYARD_CPD_ENV_KEY)" ]; then \
		env=$(env) svc=$(svc) ver=$(ver) $(MAKE) $(MAKE_ARGS) halyard-find-helm-chart-version-cpd; \
	else \
		env=$(env) svc=$(svc) ver=$(ver) $(MAKE) $(MAKE_ARGS) halyard-find-helm-chart-version; \
	fi

.PHONY: halyard-compare-versions-cpd-prod
# Compare the helm chart versions using the internal halyard `installedVersion` from cpd and prod
# yaml configs
halyard-compare-versions-cpd-prod:
	$(eval cpdVersion := $(call parse-chart-version,$(shell $(MAKE) $(MAKE_ARGS) halyard-find-helm-chart-version-$(HALYARD_CPD_ENV))))
	$(eval prodVersion := $(call parse-chart-version,$(shell $(MAKE) $(MAKE_ARGS) halyard-find-helm-chart-version-$(HALYARD_PROD_ENV))))
	@if [ "$(cpdVersion)" != "$(prodVersion)" ]; then \
		echo "helm chart version for cpd ($(cpdVersion)) does not match with prod ($(prodVersion)), please update installedVersion in $(HALYARD_CPD_ENV)"; \
		exit 1; \
	else \
		echo "helm chart version for cpd ($(cpdVersion)) matches with prod ($(prodVersion))"; \
	fi

.PHONY: halyard-find-version-from-helm-chart
# Find the internal halyard version corresponding to the helm chart version given the yaml version
# file
halyard-find-version-from-helm-chart:
ifeq ($(helmChartVersion),)
	$(error helmChartVersion must be set)
endif
	$(eval localSvc := $(call parse-service-from-yaml,$(HALYARD_DEPLOYED_VERSIONS_DIR)/$(HALYARD_ENV_TO_DEPLOY)))
	@if [ -z "$(localSvc)" ]; then \
		echo "service not found in $(HALYARD_ENV_TO_DEPLOY)"; \
		exit 1; \
	fi
	$(eval localEnv := $(call parse-environment-from-yaml,$(HALYARD_DEPLOYED_VERSIONS_DIR)/$(HALYARD_ENV_TO_DEPLOY)))
	@if [ -z "$(localEnv)" ]; then \
		echo "environment not found in $(HALYARD_ENV_TO_DEPLOY)"; \
		exit 1; \
	fi
# there may be multiple halyard versions corresponding to a given helm chart version, so find the latest version
	$(eval version := $(shell $(HALCTL) release service environment version list $(localSvc) $(localEnv) -o json | jq -c '.[] | select( .sourceVersion == "$(helmChartVersion)" )' | jq -s 'max_by(.version) | .version'))
	@echo "$(HALYARD_VERSION_IDENTIFIER)$(version)"

.PHONY: halyard-find-version-from-helm-chart-%
# Find the internal halyard version corresponding to the helm chart version given the yaml version
# file
halyard-find-version-from-helm-chart-%:
ifeq ($(helmChartVersion),)
	$(error helmChartVersion must be set)
endif
	$(eval halyardDeployedVersion := $*)
	$(eval localEnv := $(call parse-environment-from-yaml,$(HALYARD_DEPLOYED_VERSIONS_DIR)/$(halyardDeployedVersion)))
	@if [ -z "$(localEnv)" ]; then \
		echo "environment not found in $(halyardDeployedVersion)"; \
		exit 1; \
	fi
	@if [ "$(localEnv)" == "$(HALYARD_CPD_ENV_KEY)" ]; then \
		HALYARD_CPD_ENV=$(halyardDeployedVersion) helmChartVersion=$(helmChartVersion) $(MAKE) $(MAKE_ARGS) find-halyard-version-from-helm-chart-cpd; \
	else \
		HALYARD_ENV_TO_DEPLOY=$(halyardDeployedVersion) helmChartVersion=$(helmChartVersion) $(MAKE) $(MAKE_ARGS) halyard-find-version-from-helm-chart; \
	fi

.PHONY: halyard-find-default-version
halyard-find-default-version:
ifeq ($(svc),)
	$(error svc must be set)
endif
ifeq ($(env),)
	$(error env must be set)
endif
	$(eval version := $(shell $(HALCTL) release service environment list $(svc) -o json | jq -r --arg env $(env) '[.[].defaultEnvironmentVersions[$$env]]|first'))
	@echo "$(HALYARD_VERSION_IDENTIFIER)$(version)";

.PHONY: halyard-find-default-version-%
halyard-find-default-version-%:
ifeq ($(svc),)
	$(error svc must be set)
endif
	$(eval env := $*)
	@if [ "$(env)" == "$(HALYARD_CPD_ENV_KEY)" ]; then \
		svc=$(svc) $(MAKE) $(MAKE_ARGS) find-halyard-default-version-cpd; \
	else \
		env=$(env) svc=$(svc) $(MAKE) $(MAKE_ARGS) halyard-find-default-version; \
	fi

.PHONY: halyard-update-version-in-yaml-artifact-%
# Update the `installedVersion` field in the yaml versions file
halyard-update-version-in-yaml-artifact-%:
ifeq ($(halyardVersion),)
	$(error halyardVersion must be set)
endif
	$(eval halyardDeployedVersion := $*)
	@echo Setting installedVersion in yaml artifact $(HALYARD_DEPLOYED_VERSIONS_DIR)/$(halyardDeployedVersion)
# remove comments
	$(YQ) eval -i '... comments=""' $(HALYARD_DEPLOYED_VERSIONS_DIR)/$(halyardDeployedVersion)
# update version
	$(YQ) -i '.data.installedVersion = "$(halyardVersion)"' $(HALYARD_DEPLOYED_VERSIONS_DIR)/$(halyardDeployedVersion)
# add comment
	$(YQ) -i '.data.installedVersion line_comment="helm chart version $(helmChartVersion); auto-updated using mk-include"' $(HALYARD_DEPLOYED_VERSIONS_DIR)/$(halyardDeployedVersion)

.PHONY: halyard-commit-yaml-artifact-%
# Commit (and push) the updated yaml versions file
halyard-commit-yaml-artifact-%:
ifeq ($(halyardVersion),)
	$(error halyardVersion must be set)
endif
ifeq ($(helmChartVersion),)
	$(error helmChartVersion must be set)
endif
	$(eval halyardDeployedVersion := $*)
	@if ! $(GIT) diff --exit-code $(HALYARD_DEPLOYED_VERSIONS_DIR)/$(halyardDeployedVersion); then \
		echo 💬 commit to $(GIT_REMOTE_NAME) $(GIT_BRANCH_NAME); \
		$(GIT) add $(HALYARD_DEPLOYED_VERSIONS_DIR)/$(halyardDeployedVersion); \
		$(GIT) commit -m 'chore: update installedVersion to $(halyardVersion) / $(helmChartVersion) for $(halyardDeployedVersion)'; \
	fi
# Push to the release branch if we are running through CI
ifeq ($(BRANCH_NAME),$(MASTER_BRANCH))
ifeq ($(CI), true)
	@echo 💬 push changes to $(GIT_REMOTE_NAME) $(RELEASE_BRANCH)
	$(GIT) pull --rebase && \
	$(GIT) push $(GIT_REMOTE_NAME) $(RELEASE_BRANCH)
endif
endif

.PHONY: halyard-promote-service-on-yaml-artifact
# Promote the version of a service from a source environment to destination environments. The
# source environment can be provided through a yaml file with HALYARD_PROMOTE_SRC_DEPLOYED_VERSION or
# as an <svc>=<env> variable with HALYARD_PROMOTE_SRC_ENV. The destimation environments are
# provided with HALYARD_PROMOTE_DEST_DEPLOYED_VERSIONS, e.g.
# 1. HALYARD_PROMOTE_SRC_DEPLOYED_VERSION=prod.yaml HALYARD_PROMOTE_DEST_DEPLOYED_VERSIONS="cpd.yaml stag.yaml" make halyard-promote-service-on-yaml-artifact
# 2. HALYARD_PROMOTE_SRC_ENV=dd-agent=prod HALYARD_PROMOTE_DEST_DEPLOYED_VERSIONS="cpd.yaml stag.yaml" make halyard-promote-service-on-yaml-artifact
halyard-promote-service-on-yaml-artifact: $(HALYARD_PROMOTE_DEST_DEPLOYED_VERSIONS:%=promote.%)

.PHONY: $(HALYARD_PROMOTE_DEST_DEPLOYED_VERSIONS:%=promote.%)
$(HALYARD_PROMOTE_DEST_DEPLOYED_VERSIONS:%=promote.%): $(HOME)/.halctl
ifneq ($(and $(HALYARD_PROMOTE_SRC_DEPLOYED_VERSION),$(HALYARD_PROMOTE_SRC_ENV)),)
	$(error only one of HALYARD_PROMOTE_SRC_DEPLOYED_VERSION or HALYARD_PROMOTE_SRC_ENV must be set)
endif

	$(eval destYaml := $(@:promote.%=%))
	$(eval destDeployedVersionYaml := $(HALYARD_DEPLOYED_VERSIONS_DIR)/$(destYaml))

# find helm chart versions for src and dest environments
ifneq ($(HALYARD_PROMOTE_SRC_DEPLOYED_VERSION),)
	$(eval srcDeployedVersionYaml := $(HALYARD_DEPLOYED_VERSIONS_DIR)/$(HALYARD_PROMOTE_SRC_DEPLOYED_VERSION))
	$(eval srcHelmChartVersion := $(call parse-chart-version,$(shell $(MAKE) $(MAKE_ARGS) halyard-find-helm-chart-version-$(HALYARD_PROMOTE_SRC_DEPLOYED_VERSION))))
	@if [ -z "$(srcHelmChartVersion)" ]; then \
		echo "helm chart version not found for $(srcDeployedVersionYaml)"; \
		exit 1; \
	fi
else ifneq ($(HALYARD_PROMOTE_SRC_ENV),)
	$(eval srcSvc := $(word 1,$(subst =, ,$(HALYARD_PROMOTE_SRC_ENV))))
	$(eval srcEnv := $(word 2,$(subst =, ,$(HALYARD_PROMOTE_SRC_ENV))))
	$(eval srcVer := $(call parse-halyard-version,$(shell svc=$(srcSvc) $(MAKE) $(MAKE_ARGS) halyard-find-default-version-$(srcEnv))))
	$(eval srcHelmChartVersion := $(call parse-chart-version,$(shell svc=$(srcSvc) env=$(srcEnv) ver=$(srcVer) $(MAKE) $(MAKE_ARGS) halyard-find-helm-chart-version-noop)))
	@if [ -z "$(srcHelmChartVersion)" ]; then \
		echo "helm chart version not found for $(HALYARD_PROMOTE_SRC_ENV)"; \
		exit 1; \
	fi
else
	$(error either HALYARD_PROMOTE_SRC_DEPLOYED_VERSION or HALYARD_PROMOTE_SRC_ENV must be set)
endif

	$(eval destHelmChartVersion := $(call parse-chart-version,$(shell $(MAKE) $(MAKE_ARGS) halyard-find-helm-chart-version-$(destYaml))))

	@if [ "$(srcHelmChartVersion)" != "$(destHelmChartVersion)" ]; then \
		destHalyardVersion=$$(\
			helmChartVersion=$(srcHelmChartVersion) \
			$(MAKE) $(MAKE_ARGS) halyard-find-version-from-helm-chart-$(destYaml) | grep -o "$(HALYARD_VERSION_IDENTIFIER)\S*" | cut -d "=" -f2\
		); \
		halyardVersion=$$destHalyardVersion \
		helmChartVersion=$(srcHelmChartVersion) \
		$(MAKE) $(MAKE_ARGS) halyard-update-version-in-yaml-artifact-$(destYaml) halyard-commit-yaml-artifact-$(destYaml); \
	else \
		echo "helm chart version for source ($(srcHelmChartVersion)) matches with destination in $(destDeployedVersionYaml) ($(destHelmChartVersion))"; \
	fi
