import os
import re
import subprocess

import structlog

from packaging import version

logger = structlog.get_logger(__name__)


def run_cmd(cmd, env=os.environ):
    """
    cmd: String build command

    run cmd and return console output
    """
    logger.info("running", cmd=cmd)
    process = subprocess.run(cmd,
                             shell=True,
                             capture_output=True,
                             text=True,
                             env=env)
    logger.info("exited", cmd=process.args, exit_status=process.returncode)
    logger.debug("stdout", cmd=process.args, output=process.stdout)
    return process.stdout


def assert_in_output(output, assert_strings):
    """
    output: String console output
    assert_strings: Strings need to assert with output

    assert in console output with certain strings
    """
    for assert_string in assert_strings:
        assert assert_string in output
    return


def assert_not_in_output(output, assert_strings):
    """
    output: String console output

    assert not in console output with certain strings
    """
    for assert_string in assert_strings:
        assert assert_string not in output


def assert_file(file_locations):
    """
    file_locations: String file path

    assert certain file exist
    """
    for file_location in file_locations:
        assert os.path.exists(file_location) == True


def extract_version(output):
    clean_version = None
    bumped_clean_version = None
    for line in output.splitlines():
        if "bumped clean version:" in line:
            bumped_clean_version = line.split(': ')[1]
            match = re.match(r'^\d+\.\d+\.\d+$', bumped_clean_version)
            assert match != None
        elif "clean version:" in line:
            clean_version = line.split(': ')[1]
            match = re.match(r'^\d+\.\d+\.\d+$', clean_version)
            assert match != None
    return (clean_version, bumped_clean_version)


def assert_version():
    """
    assert repo version integrity
    """
    output = run_cmd("make show-version")
    (clean_version, bumped_clean_version) = extract_version(output)
    assert (version.parse(clean_version) < version.parse(bumped_clean_version))
    return


def assert_filtered_version():
    """
    assert repo version integrity given a version filter
    """
    output = run_cmd(
        "VERSION_REFS='v0.1.*' BRANCH_NAME=master make show-version")
    (clean_version, bumped_clean_version) = extract_version(output)
    assert (version.parse(clean_version) == version.parse("v0.1.0"))
    assert (version.parse(bumped_clean_version) == version.parse("v0.2.0"))
    return
