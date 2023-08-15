"""
go docker build process:
- make init-ci
- make build-docker
- make test
- make release-ci
"""
import time
from tempfile import TemporaryDirectory

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
    assert_in_output(output, ["naming to", "docker image save"])


def test_make_release():
    output = run_cmd("make release-ci")
    assert_not_in_output(output, [
        "Changes not staged for commit:",
        "recipe for target 'pre-release-check' failed"
    ])

    assert_in_output(output, [
        "git add release.svg",
    ])


def test_make_ssh():
    env = os.environ.copy()
    # Explicitly disable DOCKER_BUILDKIT mode so we can test the ssh targets
    env["DOCKER_BUILDKIT"] = "0"
    with TemporaryDirectory() as home:
        env["HOME"] = home
        os.mkdir(os.path.join(home, ".ssh"))

        for filename in ["a", "b", "c"]:
            # Allow the modified timestamp to elapse so Make can detect change
            time.sleep(1)
            with open(os.path.join(home, ".ssh", filename), "w+") as file:
                file.write("contents")
            output = run_cmd("make .ssh", env=env)
            assert_not_in_output(output, ["up to date", "Nothing to be done"])
            assert_file([os.path.join(".ssh", filename)])
