GO_SWAP_NAMESPACE ?= cc-system
GO_SWAP_DEPLOYMENT ?= $(MODULE_NAME)
GO_SWAP_COMMAND ?=
GO_SWAP_ARGS ?=
GO_SWAP_EXTRA_ARGS ?=
GO_SWAP_DEBUG ?= false
GO_SWAP_DOCKER ?= false
GO_SWAP_ALSO_PROXY ?=
GO_SWAP_EXTRA_OPTS ?=
GO_SWAP_DOCKER_IMAGE ?= confluentinc/$(IMAGE_NAME):latest
GO_SWAP_GO_BINS ?=

.PHONY: show-go-swap
show-go-swap:
	@echo "CCLOUD_ENV: $(CCLOUD_ENV)"
	@echo "GO_SWAP_NAMESPACE: $(GO_SWAP_NAMESPACE)"
	@echo "GO_SWAP_DEPLOYMENT: $(GO_SWAP_DEPLOYMENT)"
	@echo "GO_SWAP_COMMAND: $(GO_SWAP_COMMAND)"
	@echo "GO_SWAP_ARGS: $(GO_SWAP_ARGS)"
	@echo "GO_SWAP_EXTRA_ARGS: $(GO_SWAP_EXTRA_ARGS)"
	@echo "GO_SWAP_DOCKER: $(GO_SWAP_DOCKER)"
	@echo "GO_SWAP_DEBUG: $(GO_SWAP_DEBUG)"
	@echo "GO_SWAP_ALSO_PROXY: $(GO_SWAP_ALSO_PROXY)"
	@echo "GO_SWAP_EXTRA_OPTS: $(GO_SWAP_EXTRA_OPTS)"
	@echo "GO_SWAP_DOCKER_IMAGE: $(GO_SWAP_DOCKER_IMAGE)"
	@echo "GO_SWAP_GO_BINS: $(GO_SWAP_GO_BINS)"

.PHONY: go-swap-check-telp-version
go-swap-check-telp-version:
	@(telepresence --version | grep -E '^0.1[0-9]*' > /dev/null) || \
	  (echo "[ERROR] You have not yet installed telepresence v1.  Please install via 'brew install datawire/blackbird/telepresence-legacy'"; exit 255)

.PHONY: go-swap-local
go-swap-local: go-swap-check-telp-version
ifneq ($(GO_SWAP_DOCKER),true)
	GO_BINS=$(GO_SWAP_GO_BINS) $(MAKE) build-go
endif
ifdef GO_SWAP_ARGS
	$(eval args := $(GO_SWAP_ARGS))
else
	$(eval args := $(shell bash -c "kubectl -n $(GO_SWAP_NAMESPACE) get deploy/$(GO_SWAP_DEPLOYMENT) -o json | jq '.spec.template.spec.containers[0].args[]?' -r"))
endif
ifdef GO_SWAP_COMMAND
	$(eval command := $(GO_SWAP_COMMAND))
else
	$(eval command := $(shell bash -c "kubectl -n $(GO_SWAP_NAMESPACE) get deploy/$(GO_SWAP_DEPLOYMENT) -o json | jq '.spec.template.spec.containers[0].command[]?' -r"))
	$(eval split := $(subst =, ,$(GO_BINS)))
	$(eval command := $(if $(command),$(command),$(word 2,$(split))))
endif
ifeq ($(GO_SWAP_DOCKER),true)
	ulimit -n 10240 && telepresence \
	--namespace $(GO_SWAP_NAMESPACE) \
	--swap-deployment $(GO_SWAP_DEPLOYMENT) \
	$(GO_SWAP_EXTRA_OPTS) $(addprefix --also-proxy , $(GO_SWAP_ALSO_PROXY)) \
	--method container \
	--mount /tmp/telepresence/$(GO_SWAP_DEPLOYMENT) \
	--docker-run --rm --entrypoint '' -v /tmp/telepresence/$(GO_SWAP_DEPLOYMENT)/var/run/secrets:/var/run/secrets "$(GO_SWAP_DOCKER_IMAGE)" /$(command) $(args) $(GO_SWAP_EXTRA_ARGS) \
	| tee telepresence.process.log
else
ifeq ($(GO_SWAP_DEBUG),true)
	ulimit -n 10240 && telepresence \
	--namespace $(GO_SWAP_NAMESPACE) \
	--swap-deployment $(GO_SWAP_DEPLOYMENT) \
	$(GO_SWAP_EXTRA_OPTS) $(addprefix --also-proxy , $(GO_SWAP_ALSO_PROXY)) \
	--run $(MK_INCLUDE_BIN)/dlv-with-args.sh $(GO_OUTDIR)/$(command) '$(args) $(GO_SWAP_EXTRA_ARGS)' \
	| tee telepresence.process.log
else
	ulimit -n 10240 && telepresence \
	--namespace $(GO_SWAP_NAMESPACE) \
	--swap-deployment $(GO_SWAP_DEPLOYMENT) \
	$(GO_SWAP_EXTRA_OPTS) $(addprefix --also-proxy , $(GO_SWAP_ALSO_PROXY)) \
	--run $(GO_OUTDIR)/$(command) $(args) $(GO_SWAP_EXTRA_ARGS) \
	| tee telepresence.process.log
endif
endif
