
# Targets in this file help working with protos via buf: https://buf.build/
# Detailed guide available at go/buf
BUF_VERSION ?= v1.14.0

# Generate protobuf code and export .proto files during build time
GENERATE_TARGETS += buf-generate
# Install buf for protobuf compilation as an extra dependency
GO_EXTRA_DEPS += install-buf
# Make sure to lint using buf
GO_EXTRA_LINT += buf-lint


# If you used go service template, the variables below are already setup for you in your Makefile.
# If not, check go/buf for a detailed guide.
# Short version: in order for your clients to have access to the actual .proto files of your service,
# you need to use `buf export` to generate those .proto files and then use golang's `embed` package
# to actually include those files in your module.

# GRPC_SERVICE_MODULE_NAME and GRPC_SERVICE_PATH point to the module your clients would import
# when they need to talk to your service via grpc.
# .proto files will be exported under GRPC_SERVICE_PATH/buf-export.
#
# By default if you've used go service template:
# - GRPC_SERVICE_MODULE_NAME will be set to `service_name_camel_case` in your Makefile automatically
# - which means GRPC_SERVICE_PATH is pkg/api/service_name_camel_case
# Otherwise you can override BUF_ROOT and either GRPC_SERVICE_MODULE_NAME or GRPC_SERVICE_PATH directly.
# See go/buf for more information.

# Where buf.yaml is located
BUF_ROOT = $(PWD)/pkg/api
# The folder name and the path of the root of the grpc service module your clients would import.
# MAKE SURE THESE VARIABLES POINT TO THE CORRECT LOCATION
# BY SETTING EITHER OF THEM IN YOUR MAKEFILE
# GRPC_SERVICE_MODULE_NAME ?=
GRPC_SERVICE_PATH := $(BUF_ROOT)/$(GRPC_SERVICE_MODULE_NAME)
# DO NOT OVERRIDE. Otherwise your customers will look for your .protos in a wrong place.
BUF_EXPORT_PATH = $(GRPC_SERVICE_PATH)/buf-export


.PHONY: install-buf
install-buf:
	$(GO) install github.com/bufbuild/buf/cmd/buf@$(BUF_VERSION)
	$(GO) install github.com/bufbuild/buf/cmd/protoc-gen-buf-breaking@$(BUF_VERSION)
	$(GO) install github.com/bufbuild/buf/cmd/protoc-gen-buf-lint@$(BUF_VERSION)


# Use `buf-export` to export all the proto files you clients might need.
# (It's invoked automatically with `buf-generate` and `buf-lint`)
# Make sure to check-in generated files at $(BUF_EXPORT_PATH) into git
.PHONY: buf-export
buf-export: install-buf
	@echo "Removing exported protos at $(BUF_EXPORT_PATH)"
	@rm -rf $(BUF_EXPORT_PATH)
	@echo "Exporting protos to $(BUF_EXPORT_PATH)"
	@cd $(BUF_ROOT) && buf export -o $(BUF_EXPORT_PATH)

# Use `buf-generate` to generate go code from your protos
.PHONY: buf-generate
buf-generate: buf-export
	@cd $(BUF_ROOT) && buf generate --exclude-path $(BUF_EXPORT_PATH)

.PHONY: buf-lint
buf-lint: buf-export
	@cd $(BUF_ROOT) && buf lint --exclude-path $(BUF_EXPORT_PATH)
