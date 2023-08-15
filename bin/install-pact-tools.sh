#!/bin/bash
set -e

BIN_PATH=$1

ARCH=$(uname -m)
# pact binaries have lowercase OS name, while uname will return capitalized one
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

# moreover, pact binaries have 'osx' as OS type while uname will return Darwin
if [[ $OS == "darwin" ]]; then
OS="osx"
fi

function install_cli() {
    local EXEC_NAME=$1
    local BASE_URL=$2

    local EXEC_PATH="${BIN_PATH}/${EXEC_NAME}"

    local EXEC_NAME_FULL="${EXEC_NAME}-${OS}-${ARCH}"
    local ARCHIVE_NAME=${EXEC_NAME_FULL}.gz

    curl -fsSLO "${BASE_URL}/${ARCHIVE_NAME}"
    gunzip "./${ARCHIVE_NAME}"
    mv "./${EXEC_NAME_FULL}" "${EXEC_PATH}"
    chmod +x "${EXEC_PATH}"
}

# install legacy pact ruby CLI (up to pact schema v2 only)
curl -fsSL https://raw.githubusercontent.com/pact-foundation/pact-ruby-standalone/master/install.sh | bash

# install rust pact verifier CLI (supports newest pact schemas including v4)
PACT_VERIFIER_VERSION="0.10.6"
install_cli pact_verifier_cli "https://github.com/pact-foundation/pact-reference/releases/download/pact_verifier_cli-v${PACT_VERIFIER_VERSION}"


# install pact plugin manager CLI (to be able to install protobuf)
PACT_PLUGIN_CLI_VERSION="0.1.0"
install_cli pact-plugin-cli "https://github.com/pact-foundation/pact-plugins/releases/download/pact-plugin-cli-v${PACT_PLUGIN_CLI_VERSION}"


# install pact protobuf plugin
pact-plugin-cli -y install https://github.com/pactflow/pact-protobuf-plugin/releases/latest

# install pact go
go install github.com/pact-foundation/pact-go/v2@2.x.x
PACT_GO_FULL=$(which pact-go)
echo "$PACT_GO_FULL"
if [[ -n "$CI" ]]; then
    sudo "$PACT_GO_FULL" -l DEBUG install
fi
"$PACT_GO_FULL" -l DEBUG install

