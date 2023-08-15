#!/bin/bash
# install github cli if it is not installed
set -e
if ! gh --version | grep "gh version" ; then
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -O https://confluent-packaging-tools.s3-us-west-2.amazonaws.com/gh_"${GITHUB_CLI_VERSION}"_linux_amd64.deb
        sudo apt-get install -y ./gh_"${GITHUB_CLI_VERSION}"_linux_amd64.deb
        rm gh_"${GITHUB_CLI_VERSION}"_linux_amd64.deb
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install gh
    elif [[ "$OSTYPE" == "linux-musl"* ]]; then
        curl -O https://confluent-packaging-tools.s3-us-west-2.amazonaws.com/gh_"${GITHUB_CLI_VERSION}"_linux_amd64.tar.gz
        tar -xzf gh_"${GITHUB_CLI_VERSION}"_linux_amd64.tar.gz
        mv ./gh_"${GITHUB_CLI_VERSION}"_linux_amd64/bin/gh /usr/local/bin/
        rm -rf gh_"${GITHUB_CLI_VERSION}"_linux_amd64*
    fi
else
    echo "gh(github-cli) is already installed"
fi;
