# Enable secondary expansion
.SECONDEXPANSION:

# Set shell to bash
SHELL := /bin/bash

# Use this variable to specify a different make utility (e.g. remake --profile)
MAKE ?= make

# Include this file first
_empty :=
_space := $(_empty) $(empty)
_comma := ,

# Joins elements of a space separated list with the given separator.
#   first arg: separator.
#   second arg: list.
join-list = $(subst $(_space),$1,$(strip $2))

# Master branch
MASTER_BRANCH ?= master

# set default update version to master
MK_INCLUDE_UPDATE_VERSION ?= master

# enable mk-include update by default, enable auto merge mk-include change by default
UPDATE_MK_INCLUDE ?= true
UPDATE_MK_INCLUDE_AUTO_MERGE ?= true

# DevprodProd docker registries hostname
DEVPROD_PROD_AWS_ACCOUNT := 519856050701
DEVPROD_PROD_ECR := $(DEVPROD_PROD_AWS_ACCOUNT).dkr.ecr.us-west-2.amazonaws.com
DEVPROD_PROD_ECR_PROFILE := cc-internal-devprod-prod-1/developer-writer
DEVPROD_PROD_ECR_PREFIX := docker/prod
DEVPROD_PROD_ECR_REPO := $(DEVPROD_PROD_ECR)/$(DEVPROD_PROD_ECR_PREFIX)
DEVPROD_PROD_ECR_HELM_REPO_PREFIX ?= helm/prod/confluentinc/
GCLOUD_CI_AUTH_CRED := $(HOME)/.config/gcloud/application_default_credentials.json
GCLOUD_US_DOMAIN := us-docker.pkg.dev
DEVPROD_NONPROD_GAR_REPO := $(GCLOUD_US_DOMAIN)/devprod-nonprod-052022/docker/dev

ifeq (true, $(UPDATE_MK_INCLUDE))
INIT_CI_TARGETS += diff-mk-include
endif
RELEASE_TARGETS += $(_empty)
GENERATE_TARGETS += $(_empty)
BUILD_TARGETS += $(_empty)
PRE_TEST_TARGETS += $(_empty)
TEST_TARGETS += $(_empty)
POST_TEST_TARGETS += $(_empty)
CLEAN_TARGETS += $(_empty)

# If this variable is set, release will run $(MAKE) $(RELEASE_MAKE_TARGETS)
RELEASE_MAKE_TARGETS +=

ifeq ($(SEMAPHORE), true)
ifeq ($(SEMAPHORE_PROJECT_ID),)
# The SEMAPHORE_PROJECT_ID variable is only set in sem2 environments
SEMAPHORE_2 := false
else
SEMAPHORE_2 := true
endif
endif

GIT_ROOT ?= $(CURDIR)
ifeq ($(SEMAPHORE_2),true)
# TODO: try to clean up .semaphore/semaphore.yml files.
# export GO111MODULE=on
# export "GOPATH=$(go env GOPATH)"
# export "SEMAPHORE_GIT_DIR=${GOPATH}/src/github.com/confluentinc/${SEMAPHORE_PROJECT_NAME}"
# export "PATH=${GOPATH}/bin:${PATH}:/usr/local/kubebuilder/bin:/usr/local/kubebuilder"
# mkdir -vp "${SEMAPHORE_GIT_DIR}" "${GOPATH}/bin"
# export SEMAPHORE_CACHE_DIR=/home/semaphore
ifeq ($(abspath $(SEMAPHORE_GIT_DIR)),$(SEMAPHORE_GIT_DIR))
GIT_ROOT := $(SEMAPHORE_GIT_DIR)
else
GIT_ROOT := $(HOME)/$(SEMAPHORE_GIT_DIR)
endif
# Place ci-bin inside the project as Semaphore 2 only allows caching resources within the project workspace.
# This needs to be different from $(GO_OUTDIR) so it doesn't get cleaned up by clean-go target.
CI_BIN := $(GIT_ROOT)/ci-bin
else ifeq ($(SEMAPHORE),true)
GIT_ROOT := $(SEMAPHORE_PROJECT_DIR)
CI_BIN := $(SEMAPHORE_CACHE_DIR)/bin
else ifeq ($(BUILDKITE),true)
CI_BIN := /tmp/bin
endif

# Defaults
MK_INCLUDE_BIN ?= $(GIT_ROOT)/mk-include/bin
MK_INCLUDE_RESOURCE ?= $(GIT_ROOT)/mk-include/resources
MK_INCLUDE_DATA ?= $(GIT_ROOT)/mk-include/data

# Where test reports get generated, used by testbreak reporting.
ifeq ($(SEMAPHORE),true)
BUILD_DIR := $(GIT_ROOT)/build
else
BUILD_DIR := /tmp/build
endif
export BUILD_DIR

HOST_OS := $(shell uname | tr A-Z a-z)

ifeq ($(BIN_PATH),)
ifeq ($(CI),true)
BIN_PATH := $(CI_BIN)
else
ifeq ($(HOST_OS),darwin)
BIN_PATH ?= /usr/local/bin
else
ifneq ($(wildcard $(HOME)/.local/bin/.),)
BIN_PATH ?= $(HOME)/.local/bin
else
BIN_PATH ?= $(HOME)/bin
endif
endif
endif
endif

XARGS := xargs
ifeq ($(HOST_OS),linux)
XARGS += --no-run-if-empty
endif

ifeq ($(CI),true)
# downstream things (like cpd CI) assume BIN_PATH exists
$(shell mkdir -p $(BIN_PATH) 2>/dev/null)
PATH := $(BIN_PATH):$(PATH)

_ := $(shell test -d $(CI_BIN) || mkdir -p $(CI_BIN))
PATH := $(CI_BIN):$(PATH)

# pip scripts will by default get installed to this local directory
# we want to make sure they are on the path so we can call them
PYTHON_SCRIPT_DIR ?= $(HOME)/.local/bin
_ := $(shell mkdir -p $(PYTHON_SCRIPT_DIR))
PATH := $(PYTHON_SCRIPT_DIR):$(PATH)

export PATH
endif

# Retrieve the aws ec2 instance id which sempahore job is running on
ifneq ($(findstring s1-, $(SEMAPHORE_AGENT_MACHINE_TYPE)),)
INSTANCE_ID := $(shell $(MK_INCLUDE_BIN)/get_self_hosted_agent.sh)
$(info $(INSTANCE_ID))
endif

# Git stuff
BRANCH_NAME ?= $(shell git rev-parse --abbrev-ref HEAD || true)
GIT_COMMIT ?= $(shell git rev-parse HEAD || true)
# Set RELEASE_BRANCH if we're on master or vN.N.x
# special case for ce-kafka: v0.NNNN.x-N.N.N-ce-SNAPSHOT, v0.NNNN.x-N.N.N-N-ce
RELEASE_BRANCH := $(shell echo $(BRANCH_NAME) | grep -E '^($(MASTER_BRANCH)|v[0-9]+\.[0-9]+\.x(-[0-9]+\.[0-9]+\.[0-9](-[0-9])?(-ce)?(-SNAPSHOT)?)?)$$|^release-[0-9]+\.[0-9]+-confluent$$')
# assume the remote name is origin by default
GIT_REMOTE_NAME ?= origin

# Makefile called
MAKEFILE_NAME ?= Makefile
MAKE_ARGS := -f $(MAKEFILE_NAME)

# Determine if we're on a hotfix branch
ifeq ($(RELEASE_BRANCH),$(MASTER_BRANCH))
HOTFIX := false
else
HOTFIX := true
endif

# mock GIT command under CI_TEST environemnt
ifeq ($(CI_TEST),true)
GIT := echo git
else
GIT := git
endif

ifeq (true, $(UPDATE_MK_INCLUDE))
MK_INCLUDE_UPDATE_BRANCH := chore-update-mk-include
endif
# default mk-include git hash location
MK_INCLUDE_GIT_HASH_LOCATION := $(MK_INCLUDE_DATA)/mk-include-git-hash
ifeq ($(MK_INCLUDE_UPDATE_VERSION),master)
MK_INCLUDE_GIT_HASH = $(shell git ls-remote --tags git@github.com:confluentinc/cc-mk-include.git \
| sort -t '/' -k 3 -V | tail -n1 | tr -d " \t\n\r" | sed -E -e "s/refs\/(tags|heads)//")
else
MK_INCLUDE_GIT_HASH = $(shell git ls-remote --tags git@github.com:confluentinc/cc-mk-include.git $(MK_INCLUDE_UPDATE_VERSION)\
| tail -n1 | tr -d " \t\n\r" | sed -E -e "s/refs\/(tags|heads)//")
endif
MK_INCLUDE_UPDATE_COMMIT_MESSAGE := "chore: update mk-include"

GITHUB_CLI_VERSION ?= 2.13.0

ifneq ($(filter $(MK_INCLUDE_UPDATE_BRANCH),$(SEMAPHORE_GIT_PR_BRANCH) $(SEMAPHORE_GIT_BRANCH)),)
TRIGGER_PR := false
endif

ifeq ($(CI_TEST),true)
GIT := echo git
REMOVE := echo rm
GH := echo gh
else
GIT := git
REMOVE := rm
GH := gh
endif

DOCKERHUB_REPO := https://index.docker.io/v1/

# You may call `make push-docker-version` in your pipeline config to unconditionally push to dirty repo(GAR)
# In order to push to release repo(ECR), the recommend approach is to call `make release-ci` in your pipeline
# config to only push upon Branch Builds (ie: Don't push PR builds)

ifeq ($(CI),true)
# push images built on non-release branch to dirty repo
ifneq ($(RELEASE_BRANCH),$(_empty))
DOCKER_REPO ?= $(DEVPROD_PROD_ECR_REPO)
else
DOCKER_REPO ?= $(DEVPROD_NONPROD_GAR_REPO)
endif
else
DOCKER_REPO ?= $(DEVPROD_NONPROD_GAR_REPO)
endif

DOCKER_LOGIN ?= true
ifeq ($(DOCKER_LOGIN), true)
INIT_CI_TARGETS += docker-login-ci
endif

ARCH ?= $(shell uname -m)
ifeq ($(ARCH),x86_64)
ARCH := amd64
else ifeq ($(ARCH),aarch64)
ARCH := arm64
endif

RUN_COVERAGE ?= true

.PHONY: update-mk-include
update-mk-include:
	set -e ;\
	if [[ "" != $$(git status --untracked-files=no --porcelain) ]] ; then \
	echo "git must be clean to update mk-include" ;\
	exit 1 ;\
	fi ;
	@echo "update mk-include"
	$(REMOVE) -rf mk-include
	$(GIT) commit -a -m 'chore: reset mk-include'
	$(GIT) subtree add --prefix mk-include git@github.com:confluentinc/cc-mk-include.git $(MK_INCLUDE_UPDATE_VERSION) --squash
	mkdir -p $(MK_INCLUDE_DATA)
	@echo $(MK_INCLUDE_GIT_HASH) > $(MK_INCLUDE_GIT_HASH_LOCATION)
	$(GIT) add -f $(MK_INCLUDE_GIT_HASH_LOCATION)
	$(GIT) commit -m "chore: add mk-include-git-hash"

.PHONY: diff-mk-include
diff-mk-include:
ifeq ($(CI),true)
ifeq (true, $(UPDATE_MK_INCLUDE))
ifneq (false, $(TRIGGER_PR))
	@$(MAKE) install-github-cli
	export MASTER_BRANCH=$(MASTER_BRANCH) ;\
	export GIT=$(GIT) ;\
	export MK_INCLUDE_UPDATE_COMMIT_MESSAGE=$(MK_INCLUDE_UPDATE_COMMIT_MESSAGE) ;\
	export MK_INCLUDE_UPDATE_BRANCH=$(MK_INCLUDE_UPDATE_BRANCH) ;\
	export GIT_REMOTE_NAME=$(GIT_REMOTE_NAME) ;\
	export MAKE=$(MAKE) ;\
	export MK_INCLUDE_GIT_HASH=$(MK_INCLUDE_GIT_HASH) ;\
	export MK_INCLUDE_GIT_HASH_LOCATION=$(MK_INCLUDE_GIT_HASH_LOCATION) ;\
	$(MK_INCLUDE_BIN)/diff-mk-include.sh ;
else
	@echo "$(MK_INCLUDE_UPDATE_BRANCH) is already trying to update the mk-include directory, will not update and file PR"
endif
else
	@echo "auto update mk-include is disabled"
endif
else
	@echo "This command is supposed to only run in CI"
endif
	@:

.PHONY: install-github-cli
## install github cli if not installed
install-github-cli:
	export GITHUB_CLI_VERSION=$(GITHUB_CLI_VERSION) ;\
	$(MK_INCLUDE_BIN)/install-github-cli.sh
	$(GH) config set prompt disabled

.PHONY: github-cli-auth
github-cli-auth:
## login to gh cli with semaphore ci token
ifeq ($(CI),true)
	$(MK_INCLUDE_BIN)/vault-sem-get-secret semaphore_bot_github_token_file
# .githubtoken is a file contains github token and loaded form vault
# gh auth login will fail when there is a GITHUB_TOKEN env variable
	$(GH) auth login --with-token < $(HOME)/.githubtoken || true
	rm $(HOME)/.githubtoken || true
endif
	@:

.PHONY: add-github-templates
add-github-templates:
	$(eval project_root := $(shell git rev-parse --show-toplevel))
	$(eval mk_include_relative_path := ../mk-include)
	$(if $(wildcard $(project_root)/.github/pull_request_template.md),$(an error ".github/pull_request_template.md already exists, try deleting it"),)
	$(if $(filter $(BRANCH_NAME),$(MASTER_BRANCH)),$(error "You must run this command from a branch: 'git checkout -b add-github-pr-template'"),)

	@mkdir -p $(project_root)/.github
	@ln -s $(mk_include_relative_path)/.github/pull_request_template.md $(project_root)/.github
	@git add $(project_root)/.github/pull_request_template.md
	@git commit \
		-m "Add .github template for PRs $(CI_SKIP)" \
		-m "Adds the .github/pull_request_template.md as described in [1]" \
		-m "linking to the shared template in \`mk-include\`." \
		-m "" \
		-m "[1] https://github.com/confluentinc/cc-mk-include/pull/113"

	@git show
	@echo "Template added."
	@echo "Create PR with 'git push && git log --format=%B -n 1 | hub pull-request -F -'"

.PHONY: add-paas-github-templates
add-paas-github-templates:
	$(eval project_root := $(shell git rev-parse --show-toplevel))
	$(eval mk_include_relative_path := ../mk-include)
	$(if $(wildcard $(project_root)/.github/pull_request_template.md),$(an error ".github/pull_request_template.md already exists, try deleting it"),)
	$(if $(filter $(BRANCH_NAME),$(MASTER_BRANCH)),$(error "You must run this command from a branch: 'git checkout -b add-github-pr-template'"),)

	@mkdir -p $(project_root)/.github
	@ln -s $(mk_include_relative_path)/.github/paas_pull_request_template.md $(project_root)/.github/pull_request_template.md
	@git add $(project_root)/.github/pull_request_template.md
	@git commit \
		-m "Add .github template for PRs $(CI_SKIP)" \
		-m "Adds the .github/pull_request_template.md as described in [1]" \
		-m "linking to the shared template in \`mk-include\`." \
		-m "" \
		-m "[1] https://github.com/confluentinc/cc-mk-include/pull/113"

	@git show
	@echo "Template added."
	@echo "Create PR with 'git push && git log --format=%B -n 1 | hub pull-request -F -'"

.PHONY: docker-login-ci
docker-login-ci:
ifeq ($(CI),true)
	@mkdir -p $(HOME)/.docker && touch $(HOME)/.docker/config.json
# login to dockerhub as confluentsemaphore
ifeq ($(DOCKERHUB_USER)$(DOCKERHUB_APIKEY),$(_empty))
	@echo "No dockerhub creds are set, skip dockerhub docker login"
else
	@jq -e '.auths."$(DOCKERHUB_REPO)"' $(HOME)/.docker/config.json 2>&1 >/dev/null || true
	@docker login --username $(DOCKERHUB_USER) --password $(DOCKERHUB_APIKEY) || \
		docker login --username $(DOCKERHUB_USER) --password $(DOCKERHUB_APIKEY)
endif
# login to DevprodProd ECR via semaphoreCI role if not configured to use credential helper
ifneq ($(shell jq '.credHelpers."$(DEVPROD_PROD_ECR)"' $(HOME)/.docker/config.json),"ecr-login")
	@aws ecr get-login-password --region us-west-2 | \
		docker login --username AWS --password-stdin $(DEVPROD_PROD_ECR) || echo "DevProd Prod ECR login fail"
else
	@echo "Configured to use credential helper with DevProd Prod ECR, skip docker login."
endif
ifneq ($(wildcard $(GCLOUD_CI_AUTH_CRED)),)
# login to devprod GAR for dirty images
	@gcloud auth activate-service-account --key-file $(GCLOUD_CI_AUTH_CRED)
	@gcloud auth configure-docker $(GCLOUD_US_DOMAIN) -q
else
	@echo "No gcloud cred is set"
endif
endif

.PHONY: docker-login-local
docker-login-local:
## an easy command to login to ECR
	@echo "$(DEVPROD_PROD_ECR)" | docker-credential-cc-ecr-login.sh get >/dev/null

.PHONY: bats
bats:
	find . -name *.bats -exec bats {} \;

$(HOME)/.netrc:
ifeq ($(CI),true)
	$(error .netrc missing, can't authenticate to GitHub)
else
	$(shell bash -c 'echo .netrc missing, prompting for user input >&2')
	$(shell bash -c 'echo Enter Github credentials, if you use 2 factor authentication generate a personal access token for the password: https://github.com/settings/tokens >&2')
	$(eval user := $(shell bash -c 'read -p "GitHub Username: " user; echo $$user'))
	$(eval pass := $(shell bash -c 'read -s -p "GitHub Password: " pass; echo $$pass'))
	@printf "machine github.com\n\tlogin $(user)\n\tpassword $(pass)\n\nmachine api.github.com\n\tlogin $(user)\n\tpassword $(pass)\n" > $(HOME)/.netrc
	@echo
endif

ifneq ($(DOCKER_BUILDKIT),0)
export DOCKER_BUILDKIT=1

.netrc:

.ssh:

.aws:

.gitconfig:

else

.netrc: $(HOME)/.netrc
	cp $(HOME)/.netrc .netrc

.ssh: $(HOME)/.ssh
	cp -R $(HOME)/.ssh/. .ssh

.aws: $(HOME)/.aws
	cp -R $(HOME)/.aws/. .aws

.gitconfig: $(HOME)/.gitconfig
	cp $(HOME)/.gitconfig .gitconfig

endif
