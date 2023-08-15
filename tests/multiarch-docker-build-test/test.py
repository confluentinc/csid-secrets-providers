"""
go docker build process:
- make init-ci
- make build-docker
- make test
- make release-ci
"""
import os

import pytest
import structlog

structlog.configure(logger_factory=structlog.stdlib.LoggerFactory())

from tests.test_utils import *


def test_version():
    assert_version()


def test_version_filter():
    assert_filtered_version()


def test_make_show_args():
    output = run_cmd("make show-args")
    assert_in_output(output, [
        "cache-docker-base-images",
        "deps",
        "docker-login-ci",
        "gcloud-install",
        "helm-setup-ci",
        "install-vault",
        "vault-bash-functions",
    ])


def test_make_init_ci():
    output = run_cmd("make init-ci")
    assert_in_output(output, [
        "all modules verified",
        "cache restore 519856050701.dkr.ecr.us-west-2.amazonaws.com/docker/prod/confluentinc/cc-built-base:v1.1.0",
    ])
    assert_file(["/home/semaphore/.docker/config.json"])


def test_make_build_docker():
    output = run_cmd("make build-docker 2>&1")
    assert_in_output(output, [
        "Install arm64 emulation", "--platform linux/arm64",
        "--platform linux/amd64"
    ])


def test_make_release():
    branch = os.environ.get('SEMAPHORE_GIT_WORKING_BRANCH',"")
    docker_registry = "us-docker.pkg.dev/devprod-nonprod-052022/docker/dev"
    if branch == "master":
        docker_registry = "519856050701.dkr.ecr.us-west-2.amazonaws.com/docker/prod"
        
    output = run_cmd("make release-ci")
    assert_not_in_output(output, [
        "Changes not staged for commit:",
        "recipe for target 'pre-release-check' failed"
    ])

    assert_in_output(output, [
        "git add release.svg",
        "docker push " + docker_registry + "/confluentinc/cc-test-service:latest-amd64",
        "docker push " + docker_registry + "/confluentinc/cc-test-service:latest-arm64",
        "docker manifest push " + docker_registry + "/confluentinc/cc-test-service:latest"
    ])
