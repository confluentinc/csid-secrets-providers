"""
- make diff-mk-include
# export UPDATE_MK_INCLUDE to true
- make diff-mk-include
# test chore-update-mk-include branch condition

"""
import pytest
import structlog

structlog.configure(logger_factory=structlog.stdlib.LoggerFactory())

from tests.test_utils import *


def test_args():
    output = run_cmd("make show-args")

    assert_in_output(output, [
        "INIT_CI_TARGETS: "
    ])
