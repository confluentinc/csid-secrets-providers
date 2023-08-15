# Defaults
GO ?= $(shell which go)# default go bin to whatever's on the path
GO_VERSION := $(subst go,,$(shell $(GO) env GOVERSION))# the version of the go bin
GO_ALPINE ?= false# default to not alpine because most people will be building locally on macs
GO_STATIC ?= true# default to static binaries
GO_BINS ?= main.go=main# format: space seperated list of source.go=output_bin
GO_OUTDIR ?= bin# default to output bins to bin/
GO_LDFLAGS ?= -X main.version=$(VERSION)# Setup LD Flags
GO_EXTRA_TAGS ?= # space separated list of tags to add when running go build
GO_EXTRA_FLAGS ?=
GO_EXTRA_DEPS ?=
GO_FIPS_ENV_VARS ?=
GO_FIPS_ENABLE_INPLACE ?= false

GO_VERSION_MAJOR := $(or $(word 1,$(subst ., ,$(GO_VERSION))),0)
GO_VERSION_MINOR := $(or $(word 2,$(subst ., ,$(GO_VERSION))),0)
GO_VERSION_PATCH := $(or $(word 3,$(subst ., ,$(GO_VERSION))),0)

# port to which dlv debugger attaches
GOLAND_PORT ?= 12345
# path to Jetbrains Go plugin
GOLAND_PLUGIN_PATH ?= /Applications/GoLand.app/Contents/plugins/go/

GO_COVERAGE_PROFILE ?= coverage.txt
GO_COVERAGE_HTML ?= coverage.html
GO_COVERAGE_GATE ?= 80

# Whether to use go module vendoring, see https://golang.org/ref/mod#go-mod-vendor
#
# If we want to use local dependencies while running Go commands, one way to do that is to enable go vendoring
# Then in our dockerfile, we can copy the vendor folder to our image, and go commands like go build will
# use the vendor folder for dependencies
# There are other ways to use local go dependencies, but enabling vendoring is the simplest.
#
# After enabling this flag, you can change your Dockerfile from:
#
# COPY go.mod go.sum Makefile ./
# COPY mk-include ./mk-include
# RUN --mount=type=ssh CGO_ENABLED=0 make deps
#
# COPY . .
#
# To just be:
#
# COPY . .
GO_USE_VENDOR ?=

GO_TEST_SETUP_CMD ?= :
GO_TEST_ARGS ?= -race -v -cover# default list of args to pass to go test
ifdef TESTS_TO_RUN
GO_TEST_ARGS += -run "$(TESTS_TO_RUN)"
endif
GO_TEST_PACKAGE_ARGS ?= ./...

GO_GENERATE_ARGS ?= ./...

# use golangci-lint
GOLANGCI_LINT_VERSION ?= 1.52.2
GOLANGCI_LINT ?= false
GOLANGCI_LINT_CONFIG ?= $(MK_INCLUDE_RESOURCE)/.golangci.yml
GOLANGCI_LINT_TESTS ?= false
GOLANGCI_LINT_TESTS_CONFIG ?= $(MK_INCLUDE_RESOURCE)/.golangci-tests.yml

GOARCH_USE_HOST_ARCH ?= false
ifeq ($(GOARCH_USE_HOST_ARCH), true)
GOARCH ?= $(ARCH)
else
GOARCH ?= amd64
endif

# Usage: $(call go-version-at-least,MAJOR,[MINOR,[PATCH]])
# Test whether the current Go toolchain version satisfies a minimum version.
# On success, expands to the current Go version. Otherwise, expands to the empty
# string. If MINOR or PATCH are not specified, they default to 0.
# Example:
#   ifneq (,$(call go-version-at-least,1,19)
#     ... actions for Go versions 1.19 and newer
#   endif
go-version-at-least = $(strip $(shell \
		test $$(( ((($(GO_VERSION_MAJOR)*1000)+$(GO_VERSION_MINOR))*1000)+$(GO_VERSION_PATCH) )) \
			-ge $$(( ((($(1)*1000)+$(or $(2),0))*1000)+$(or $(3),0) )) \
		&& echo $(GO_VERSION) \
	))

# install golangci-linter
ifeq ($(GOLANGCI_LINT), true)
GO_EXTRA_DEPS += install-golangci-lint
endif

# run the golangci-linter in CI if enabled above
ifeq ($(CI), true)
GO_EXTRA_LINT += _go-golangci-lint-ci
else
GO_EXTRA_LINT += go-golangci-lint
endif

# FIPS
ifeq ($(GO_FIPS_ENABLE_INPLACE),true)
ifneq (,$(call go-version-at-least,1,19))
GO_FIPS_ENV_VARS = CGO_ENABLED=1 GOOS=linux GOARCH=$(GOARCH)
GO_EXPERIMENTS += boringcrypto
endif
endif

# flags for confluent-kafka-go-dev / librdkafka on alpine
ifeq ($(GO_ALPINE),true)
GO_EXTRA_TAGS += musl
endif

# force rebuild of all packages on CI
ifeq ($(CI),true)
GO_EXTRA_FLAGS += -a
endif

# Build the listed main packages and everything they import into executables
ifeq ($(GO_STATIC),true)
GO_EXTRA_FLAGS += -buildmode=exe
GO_EXTRA_TAGS += static_all
endif

# Improve reproducability of Go binaries by disabling behaviors that embed
# details of the build environment (like working directory) in the executable.
ifeq ($(CI),true)
# Currently gated to CI jobs due to concerns about debugger compatibility with
# trimmed paths.
ifneq (,$(call go-version-at-least,1,19))
# Gated on Go 1.19 because this version fixed the behavior of 'go generate'
# when running generators built with -trimpath.
# https://tip.golang.org/doc/go1.19
GO_EXTRA_FLAGS += -trimpath
endif
endif

# List of all go files in project
ALL_SRC = $(shell \
	find . \
	-type d \( \
		-path ./vendor \
		-o -path ./.gomodcache \
		-o -path ./.semaphore-cache \
		-o -path ./mk-include \
	\) -prune \
	-o -name \*.go -not -name bindata.go -print \
)

# CLI Doc gen stuff
CLI_DOCS_GEN_MAINS ?= # Default to empty
CLI_DOCS_GEN_DIRS := $(dir $(CLI_DOCS_GEN_MAINS))

# Force go mod on
GO111MODULE := on
export GO111MODULE

# Mark confluentinc projects as private
GOPRIVATE ?= github.com/confluentinc/*
export GOPRIVATE

# Disable go mod changes on CI
ifeq ($(CI),true)
GO_MOD_DOWNLOAD_MODE_FLAG ?= -mod=readonly
else
GO_MOD_DOWNLOAD_MODE_FLAG ?=
endif

# Allow for opt out of module prefetching on CI
GO_PREFETCH_DEPS ?= true

GOPATH ?= $(shell $(GO) env GOPATH)

GO_GENERATE_TARGET ?= generate-go
GO_BUILD_TARGET ?= build-go
GO_TEST_TARGET ?= lint-go test-go
GO_SYNTHETIC_TEST_TARGET ?= lint-go test-go-synthetic
GO_CLEAN_TARGET ?= clean-go

# Project Pyramid - enable local mode testing in CI checks.
LOCAL_MODE_TEST_BINS ?= $(foreach gobin,$(call FILTER,cmd/server,$(GO_BINS)),$(GO_OUTDIR)/$(word 2,$(subst =, ,$(gobin))))
# Note: These are set to true for new services in cc-go-template-service
LOCAL_MODE_TEST_ENABLE ?= false
LOCAL_MODE_TEST_FAIL_CI ?= false
ifeq ($(LOCAL_MODE_TEST_ENABLE),true)
GO_TEST_TARGET += go-test-local-mode
endif

ifeq ($(GO_PREFETCH_DEPS),true)
INIT_CI_TARGETS += deps
endif
GENERATE_TARGETS += $(GO_GENERATE_TARGET)
BUILD_TARGETS += $(GO_BUILD_TARGET) gen-cli-docs-go
TEST_TARGETS += $(GO_TEST_TARGET)
SYNTHETIC_TEST_TARGETS += $(GO_SYNTHETIC_TEST_TARGET)
CLEAN_TARGETS += $(GO_CLEAN_TARGET)
RELEASE_PRECOMMIT += commit-cli-docs-go
RELEASE_POSTCOMMIT += $(GO_DOWNSTREAM_DEPS)

GO_BINDATA_VERSION := 3.23.0
GO_BINDATA_OPTIONS ?=
GO_BINDATA_OUTPUT ?= deploy/bindata.go

ifeq ($(CI),true)
# Override the DB_URL for go tests that need access to postgres
DB_URL ?= postgres://$(DATABASE_POSTGRESQL_USERNAME):$(DATABASE_POSTGRESQL_PASSWORD)@127.0.0.1:5432/mothership?sslmode=disable
export DB_URL
endif

.PHONY: show-go
## Show Go Variables
show-go:
	@echo "GO: $(GO)"
	@echo "GO_VERSION: $(GO_VERSION)"
	@echo "GO_BINS: $(GO_BINS)"
	@echo "GO_OUTDIR: $(GO_OUTDIR)"
	@echo "GO_LDFLAGS: $(GO_LDFLAGS)"
	@echo "GO_EXTRA_TAGS: $(GO_EXTRA_TAGS)"
	@echo "GO_EXTRA_FLAGS: $(GO_EXTRA_FLAGS)"
	@echo "GO_EXTRA_DEPS: $(GO_EXTRA_DEPS)"
	@echo "GO_MOD_DOWNLOAD_MODE_FLAG: $(GO_MOD_DOWNLOAD_MODE_FLAG)"
	@echo "GO_ALPINE: $(GO_ALPINE)"
	@echo "GO_STATIC: $(GO_STATIC)"
	@echo "GO111MODULE: $(GO111MODULE)"
	@echo "GOPATH: $(GOPATH)"
	@echo "GO_BINDATA_VERSION: $(GO_BINDATA_VERSION)"
	@echo "DB_URL: $(DB_URL)"
	@echo "GO_DOWNSTREAM_DEPS: $(GO_DOWNSTREAM_DEPS)"
	@echo "CLI_DOCS_GEN_MAINS: $(CLI_DOCS_GEN_MAINS)"
	@echo "GO_PREFETCH_DEPS: $(GO_PREFETCH_DEPS)"
	@echo "GO_TEST_ARGS: $(GO_TEST_ARGS)"
	@echo "GO_TEST_PACKAGE_ARGS: $(GO_TEST_PACKAGE_ARGS)"
	@echo "GO_EXTRA_LINT: $(GO_EXTRA_LINT)"
	@echo "LOCAL_MODE_TEST_BINS: $(LOCAL_MODE_TEST_BINS)"

.PHONY: clean-go
clean-go:
ifeq ($(abspath $(GO_OUTDIR)),$(abspath $(BIN_PATH)))
	@echo "WARNING: Your project is deleting BIN_PATH contents during clean-go."
	@echo "BIN_PATH: $(BIN_PATH), abs: $(abspath $(BIN_PATH))"
	@echo "CI_BIN: $(CI_BIN), abs: $(abspath $(CI_BIN))"
	@echo "GO_OUTDIR: $(GO_OUTDIR), abs: $(abspath $(GO_OUTDIR))"
endif
	rm -rf $(SERVICE_NAME) $(GO_OUTDIR)

.PHONY: vet
vet:
	$(GO) list $(GO_MOD_DOWNLOAD_MODE_FLAG) $(GO_TEST_PACKAGE_ARGS) | grep -v vendor | xargs $(GO) vet $(GO_MOD_DOWNLOAD_MODE_FLAG)

.PHONY: deps
## fetch any dependencies - go mod download is opt out
deps: $(HOME)/.hgrc $$(GO_EXTRA_DEPS)
	$(GO) mod download
	$(GO) mod verify
ifeq ($(GO_USE_VENDOR),-mod=vendor)
	$(GO) mod vendor
endif

$(HOME)/.hgrc:
	echo -e '[ui]\ntls = False' > $@

.gomodcache:
	mkdir .gomodcache || true

.PHONY: lint-go
## Lints (gofmt)
lint-go: $(GO_EXTRA_LINT)
	@gofmt -e -s -l -d $(ALL_SRC)

.PHONY: fmt
## Format entire codebase
fmt:
	@gofmt -e -s -l -w $(ALL_SRC)

.PHONY: build-go
## Build just the go project
build-go: go-bindata $(GO_BINS)
$(GO_BINS):
# Build GO_TAGS based off of GO_EXTRA_TAGS - we define a new var because for services with multiple binaries,
# this make target will be run multiple times, so we don't want to add -tag -tag -tag $(GO_EXTRA_TAGS)
	$(if $(GO_EXTRA_TAGS),$(eval GO_TAGS=-tags $(call join-list,$(_comma),$(GO_EXTRA_TAGS))))
	$(eval split := $(subst =, ,$(@)))
	$(if $(GO_EXPERIMENTS),GOEXPERIMENT=$(subst $(_space),$(_comma),$(GO_EXPERIMENTS))) \
	$(GO_FIPS_ENV_VARS) $(GO) build $(GO_USE_VENDOR) $(GO_MOD_DOWNLOAD_MODE_FLAG) -o $(GO_OUTDIR)/$(word 2,$(split)) -ldflags "$(GO_LDFLAGS)" $(GO_TAGS) $(GO_EXTRA_FLAGS) $(word 1,$(split))

.PHONY: test-go
## Run Go Tests and Vet code
test-go: vet
	test -f $(GO_COVERAGE_PROFILE) && truncate -s 0 $(GO_COVERAGE_PROFILE) || true
	set -o pipefail && $(GO_TEST_SETUP_CMD) && \
	$(if $(GO_EXPERIMENTS),GOEXPERIMENT=$(subst $(_space),$(_comma),$(GO_EXPERIMENTS))) \
	$(GO_FIPS_ENV_VARS) $(GO) test $(GO_MOD_DOWNLOAD_MODE_FLAG) -coverprofile=$(GO_COVERAGE_PROFILE) $(GO_TEST_BUILD_ARGS) $(GO_TEST_ARGS) $(GO_TEST_PACKAGE_ARGS) -json > >($(MK_INCLUDE_BIN)/decode_test2json.py) 2> >($(MK_INCLUDE_BIN)/color_errors.py >&2)

# by default this is make coverage.html
$(GO_COVERAGE_HTML): $(GO_COVERAGE_PROFILE)
	$(GO) tool cover -html "$(GO_COVERAGE_PROFILE)" -o "$(GO_COVERAGE_HTML)"

.PHONY: go-coverage-html
# opens an html page to go coverage
go-coverage-html: $(GO_COVERAGE_PROFILE)
	$(GO) tool cover -html "$(GO_COVERAGE_PROFILE)"

.PHONY: print-coverage-out
print-coverage-out: $(GO_COVERAGE_PROFILE)
	$(GO) tool cover -func "$(GO_COVERAGE_PROFILE)"

.PHONY: go-gate-coverage
## Extract test coverage percent, and fail if under environment variable GO_COVERAGE_GATE
go-gate-coverage: $(GO_COVERAGE_PROFILE)
	$(eval coverage_percent :=  $(shell \
		$(MAKE) print-coverage-out | \
		grep 'total' | \
		tail -n 1 | \
		awk '{print substr($$3, 1, length($$3)-1)}' \
	))
	@echo "have coverage percentage of $(coverage_percent)"
	@echo "testing coverage: $(coverage_percent) >= $(GO_COVERAGE_GATE)"
	@bash -c "(( \$$(echo '$(coverage_percent) >= $(GO_COVERAGE_GATE)' | bc -l) ))"

.PHONY: test-go-goland-debug
## Vet code, Launch Go Tests and wait for GoLand debugger to attach on ${DEBUG_PORT}
test-go-goland-debug: vet
ifeq ($(GO_TEST_PACKAGE_ARGS),./...)
	@echo "Error: must specify a test/package using GO_TEST_PACKAGE_ARGS= on the commandline"
	@echo "Usage: GO_TEST_PACKAGE_ARGS=./test/connect/... make $@" && exit 1
endif
	test -f $(GO_COVERAGE_PROFILE) && truncate -s 0 $(GO_COVERAGE_PROFILE) || true
	go test -c $(GO_MOD_DOWNLOAD_MODE_FLAG) $(GO_TEST_PACKAGE_ARGS) -gcflags='all=-N -l'
	$(eval go_test_binary := $(shell echo "$(GO_TEST_PACKAGE_ARGS)" | awk -F/ '{print "./"$$(NF - 1)"."$$2}'))
	$(eval prefixed_go_test_args := $(shell echo "$(GO_TEST_ARGS)" |  sed 's/-/-test./g'))
	$(eval goland_dlv_cmd := $(GOLAND_PLUGIN_PATH)/lib/dlv/mac/dlv --listen=0.0.0.0:$(GOLAND_PORT) --headless=true --api-version=2 --check-go-version=false --only-same-user=false)
	set -o pipefail && go tool test2json -t ${goland_dlv_cmd} exec ${go_test_binary} -- ${prefixed_go_test_args} | $(MK_INCLUDE_BIN)/decode_test2json.py

FILTER = $(foreach v,$(2),$(if $(findstring $(1),$(v)),$(v),))

.PHONY: go-test-local-mode $(LOCAL_MODE_TEST_BINS:%=%.local-mode)
## Test that local mode works (Project Pyramid).
go-test-local-mode: $(LOCAL_MODE_TEST_BINS:%=%.local-mode)

$(LOCAL_MODE_TEST_BINS:%=%.local-mode): $(LOCAL_MODE_TEST_BINS)
	@LOCAL_MODE_TEST_FAIL_CI=$(LOCAL_MODE_TEST_FAIL_CI) ./mk-include/bin/local_mode_test.sh $(@:%.local-mode=%)

.PHONY: generate-go
## Run go generate
generate-go:
	$(GO) generate $(GO_MOD_DOWNLOAD_MODE_FLAG) $(GO_GENERATE_ARGS)

SEED_POSTGRES_URL ?= postgres://
SEED_POSTGRES_FILES ?= $(shell find mk-include/seed-db/sql -iname "*.sql")

.PHONY: seed-local-mothership
## Seed local mothership DB. Optionally set SEED_POSTGRES_URL for base postgres url
seed-local-mothership:
	@echo "Seeding postgres in 'SEED_POSTGRES_URL=${SEED_POSTGRES_URL}' with ${SEED_POSTGRES_FILES}. Set SEED_POSTGRES_URL/SEED_POSTGRES_FILES to override"
	psql -P pager=off ${SEED_POSTGRES_URL}/postgres -c 'DROP DATABASE IF EXISTS mothership;'
	psql -P pager=off ${SEED_POSTGRES_URL}/postgres -c 'CREATE DATABASE mothership;'
	@echo ${SEED_POSTGRES_FILES} | xargs -n1 -t psql -P pager=off ${SEED_POSTGRES_URL}/mothership -f

.PHONY: install-go-bindata
GO_BINDATA_INSTALLED_VERSION := $(shell $(BIN_PATH)/go-bindata -version 2>/dev/null | head -n 1 | awk '{print $$2}' | xargs)
install-go-bindata:
	@echo "go-bindata installed version: $(GO_BINDATA_INSTALLED_VERSION)"
	@echo "go-bindata want version: $(GO_BINDATA_VERSION)"
ifneq ($(GO_BINDATA_INSTALLED_VERSION),$(GO_BINDATA_VERSION))
	mkdir -p $(BIN_PATH)
	curl -L -o $(BIN_PATH)/go-bindata https://github.com/kevinburke/go-bindata/releases/download/v$(GO_BINDATA_VERSION)/go-bindata-$(shell $(GO) env GOOS)-$(shell $(GO) env GOARCH)
	chmod +x $(BIN_PATH)/go-bindata
endif

.PHONY: go-bindata
ifneq ($(GO_BINDATA_OPTIONS),)
## Run go-bindata for project
go-bindata: install-go-bindata install-github-cli
	$(BIN_PATH)/go-bindata $(GO_BINDATA_OPTIONS)
	@echo
	@echo "Here is the list of static assets bundled by go-bindata:"
	@sed -n '/\/\/ sources:/,/^$$/p' $(GO_BINDATA_OUTPUT)
ifeq ($(CI),true)
ifeq ($(findstring pull-request,$(BRANCH_NAME) $(SEMAPHORE_GIT_REF_TYPE)),pull-request)
	git diff --exit-code --name-status || \
		(echo "ERROR: cannot commit changes back to a fork, please run go-bindata locally and commit the changes" && \
		gh api -XPOST repos/${SEMAPHORE_GIT_PR_SLUG}/issues/${SEMAPHORE_GIT_PR_NUMBER}/comments -F body=@mk-include/resources/gh-comment-go-bindata.md && \
		exit 1)
else
	git diff --exit-code --name-status || \
		(git add $(GO_BINDATA_OUTPUT) && \
		git commit -m 'chore: updating bindata' && \
		git push $(GIT_REMOTE_NAME) $(BRANCH_NAME))
endif
endif
else
go-bindata:
endif

.PHONY: gen-cli-docs-go $(CLI_DOCS_GEN_MAINS)
## Generate go cli docs if generator file is specified
gen-cli-docs-go: $(CLI_DOCS_GEN_MAINS)
$(CLI_DOCS_GEN_MAINS):
	$(GO) run $(GO_MOD_DOWNLOAD_MODE_FLAG) $@

.PHONY: commit-cli-docs-go $(CLI_DOCS_GEN_DIRS)
commit-cli-docs-go: $(CLI_DOCS_GEN_DIRS)
	@:
$(CLI_DOCS_GEN_DIRS):
	git diff --exit-code --name-status $@ || \
		(git add $@ && \
		git commit -m 'chore: updating cli docs [ci skip]')

.PHONY: go-update-deps
## Update dependencies (go get -u)
go-update-deps:
ifeq ($(HOTFIX),true)
	$(GO) get -u=patch
else
	$(GO) get -u
endif
	$(GO) mod tidy

.PHONY: go-update-dep
## Update single dependency, specify with DEP=
go-update-dep:
ifeq ($(DEP),)
	@echo "Error: must specify DEP= on the commandline"
	@echo "Usage: $(MAKE) go-update-dep DEP=github.com/confluentinc/example@v1.2.3"
else
	$(GO) get $(DEP)
	$(GO) mod tidy
endif

.PHONY: go-commit-deps
## Commit (and push) updated go deps.
## NOTE: Some repos have go.sum in `.gitignore`. We use `git ls-files` to only
## add go.sum if it's tracked by git.
go-commit-deps:
	git diff --exit-code --name-status || \
		(git add $$(git ls-files go.mod go.sum) && \
		git commit -m 'chore: $(UPSTREAM_MOD):$(UPSTREAM_VERSION) updating go deps' && \
		git push $(GIT_REMOTE_NAME) $(GIT_BRANCH_NAME))

.PHONY: $(GO_DOWNSTREAM_DEPS)
$(GO_DOWNSTREAM_DEPS):
ifeq ($(HOTFIX),true)
	@echo "Skipping bumping downstream go dep $@ on hotfix branch"
else ifeq ($(BUMP),major)
	@echo "Skipping bumping downstream go dep $@ with major version bump"
else
	git clone git@github.com:confluentinc/$@.git $@
	$(MAKE) $(MAKE_ARGS) -C $@ go-update-dep go-commit-deps \
		DEP=$(shell grep module go.mod | awk '{print $$2}')@$(BUMPED_VERSION) \
		UPSTREAM_MOD=$(SERVICE_NAME) \
		UPSTREAM_VERSION=$(BUMPED_VERSION)
	rm -rf $@
endif

.PHONY: go-component-tests
## (POC) Component testing
go-component-tests:
	$(MK_INCLUDE_BIN)/copy_protos.sh
	$(MK_INCLUDE_BIN)/run_component_test.sh

.PHONY: install-golangci-lint
install-golangci-lint:
	@echo "Installing golangci-lint"
	$(GO) install github.com/golangci/golangci-lint/cmd/golangci-lint@v$(GOLANGCI_LINT_VERSION)
	@echo "Done"

.PHONY: go-golangci-lint
## Run golangci-lint
go-golangci-lint:
ifeq ($(GOLANGCI_LINT),true)
	@CGO_ENABLED=1 golangci-lint run --config $(GOLANGCI_LINT_CONFIG)
endif
ifeq ($(GOLANGCI_LINT_TESTS),true)
	@CGO_ENABLED=1 golangci-lint run --config $(GOLANGCI_LINT_TESTS_CONFIG)
endif

.PHONY: go-golangci-fix
## Run golangci-lint auto fix
go-golangci-fix:
ifeq ($(GOLANGCI_LINT),true)
	@CGO_ENABLED=1 golangci-lint run --config $(GOLANGCI_LINT_CONFIG) --fix
endif
ifeq ($(GOLANGCI_LINT_TESTS),true)
	@CGO_ENABLED=1 golangci-lint run --config $(GOLANGCI_LINT_TESTS_CONFIG) --fix
endif

.PHONY: go-golangci-clean
## Clean the golangci-lint cache
go-golangci-clean:
	@CGO_ENABLED=1 golangci-lint cache clean

.PHONY: _go-golangci-lint-ci
_go-golangci-lint-ci: github-cli-auth
ifeq ($(GOLANGCI_LINT),true)
	$(MAKE) go-golangci-lint | tee golangci-lint.output
	./mk-include/bin/comment-pr-golangci-lint.sh
endif
ifeq ($(GOLANGCI_LINT_TESTS),true)
	$(MAKE) go-golangci-lint-tests | tee golangci-lint.output
	./mk-include/bin/comment-pr-golangci-lint.sh
endif

.PHONY: _go-golangci-local
_go-golangci-local:
ifeq ($(GOLANGCI_LINT),true)
	$(MAKE) go-golangci-lint
endif
ifeq ($(GOLANGCI_LINT_TESTS),true)
	$(MAKE) go-golangci-lint-tests
endif
