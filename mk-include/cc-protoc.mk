PROTOC := $(BIN_PATH)/protoc
PROTOC_VERSION ?= 3.9.0
PROTOC_INSTALLED_VERSION := $(shell $(PROTOC) --version 2>/dev/null protoc | awk '{print $$2}')

uname := $(shell uname)
ifeq ($(uname),Darwin)
PROTOC_OS := osx
else ifeq ($(uname),Linux)
PROTOC_OS := linux
endif

PROTOC_ARCH := $(shell uname -m)

# for arm64, older versions of protobuf dont have an arm64 (aarch_64)
# version. OSX supports running the x86_64 version directly as well so
# retry with that if arm64 is missing. also, the spelling for arm64 is
# aarch_64 for the arch for protobuf downloads
ifeq ($(PROTOC_ARCH),arm64)
  define PROTOC_DOWNLOAD_CMD
	( \
	  curl --fail -L -o /tmp/protoc/protoc.zip https://github.com/protocolbuffers/protobuf/releases/download/v$(PROTOC_VERSION)/protoc-$(PROTOC_VERSION)-$(PROTOC_OS)-aarch_64.zip || \
	  curl --fail -L -o /tmp/protoc/protoc.zip https://github.com/protocolbuffers/protobuf/releases/download/v$(PROTOC_VERSION)/protoc-$(PROTOC_VERSION)-$(PROTOC_OS)-x86_64.zip \
	)
  endef
else
  define PROTOC_DOWNLOAD_CMD
	curl --fail -L -o /tmp/protoc/protoc.zip https://github.com/protocolbuffers/protobuf/releases/download/v$(PROTOC_VERSION)/protoc-$(PROTOC_VERSION)-$(PROTOC_OS)-$(PROTOC_ARCH).zip
  endef
endif

.PHONY: install-protoc
install-protoc:
ifneq ($(PROTOC_VERSION),$(PROTOC_INSTALLED_VERSION))
	mkdir -p /tmp/protoc && \
	$(PROTOC_DOWNLOAD_CMD) && \
	cd /tmp/protoc && \
	unzip -jo protoc.zip -d $(BIN_PATH) bin/protoc && \
	unzip -o protoc.zip -d $(BIN_PATH) include/* && \
	rm -rf /tmp/protoc
endif

.PHONY: clean-protoc
clean-protoc:
	rm -rf $(BIN_PATH)/protoc
	rm -rf $(BIN_PATH)/../include/google
