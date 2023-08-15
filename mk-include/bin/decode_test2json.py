#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
This command line script is intended to process go test2json output.
The test output needs to be generated with the `-json` flag which enables
the test2json output; doing so also enables the unbuffered test output
(by default output is buffered until test finishes) which is very
useful but it is not a documented behavior.

More info about the test2json output: https://golang.org/cmd/test2json/
"""

import fileinput
import json
import os
import pprint
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from typing import Collection, List, Optional
from xml.dom.minidom import Document
import argparse

# The different testcase statuses.
PASS, FAIL, SKIP, TIMEOUT, PANIC, FLAKY = 'PASS', 'FAIL', 'SKIP', 'TIMEOUT', 'PANIC', 'FLAKY'

# The associated emojis.
SYMBOLS = {
    PASS: '✅',
    FAIL: '❌',
    FLAKY: '🟡',
    TIMEOUT: '🕘',
    PANIC: '🔥',
    SKIP: '🤞',
}

# Special patterns to look for in go test outputs.
PANIC_MESSAGE = 'panic: '
TIMEOUT_MESSAGE = 'panic: test timed out after'
CI = os.environ.get('CI', "false").lower() == "true"
TEST_REPORT_FILE_NAME = "TEST-result.xml"
if CI:
    TEST_REPORT_FILE_NAME = f'{os.environ.get("SEMAPHORE_PIPELINE_ID", "")}-{TEST_REPORT_FILE_NAME}'

# Where to put the report files.
if 'TEST_REPORT_FILE' in os.environ:
    TEST_REPORT_FILE = os.path.abspath(os.environ['TEST_REPORT_FILE'])
    TEST_REPORT_FILE_NAME = os.path.basename(TEST_REPORT_FILE)
    BUILD_DIR = os.path.dirname(TEST_REPORT_FILE)
else:
    BUILD_DIR = os.path.abspath(os.environ.get('BUILD_DIR', 'build'))
    TEST_REPORT_FILE = os.path.join(BUILD_DIR, TEST_REPORT_FILE_NAME)
FAILED_TESTS = os.path.join(BUILD_DIR, "rerun-data", "failed_test.txt")


@dataclass(frozen=True)
class Testcase:
    name: str
    status: str
    lines: List[str]
    elapsed: float
    timestamp: float


class TestBuilder:
    """
    Class used to collect information about a testcase, its status and output.
    """
    name: str
    elapsed: Optional[float]
    timestamp: Optional[float]
    status: Optional[str]
    lines: List[str]

    def __init__(self, test_name):
        self.name = test_name
        self.elapsed = None
        self.lines = []
        self.status = None
        self.timestamp = None

    def update_status(self, status):
        if not self.status and status:
            self.status = status
        elif self.status and status and self.status != FLAKY:
            # if one of the status's is passing, and there is any other status,
            # set to flaky, otherwise overwrite the status (ie: FAILED, then timeout
            # should overwrite the FAILED with TIMEOUT)
            self.status = FLAKY if self.status != status and PASS in (self.status, status) else status

    def report(self, status, timestamp, elapsed):
        self.update_status(status)
        self.timestamp = timestamp
        self.elapsed = elapsed

    def add_output(self, line):
        if line.startswith(TIMEOUT_MESSAGE):
            self.status = TIMEOUT
        elif line.startswith(PANIC_MESSAGE):
            self.status = PANIC

        self.lines.append(line)

    def build(self) -> Testcase:
        return Testcase(self.name, self.status, self.lines, self.elapsed, self.timestamp)


class Testsuite:
    """
    Class used to collect stats about multiple testcases falling under the
    same package / testsuite.
    """
    counts: Counter
    panic: bool
    lines: List[str]
    tests: Collection[Testcase]
    test_builders: Collection[TestBuilder]
    total: int

    elapsed: Optional[float] = None
    package: Optional[str] = None
    timeout: Optional[float] = None
    timestamp: Optional[float] = None

    def __init__(self):
        self.counts = Counter()
        self.lines = []
        self.panic = False
        self.test_builders = {}
        self.total = 0

        self.elapsed = None
        self.package = None
        self.timeout = None
        self.elapsed = None

    def run(self, test):
        if test is None:
            return

        _ = self.get_test_builder(test)
        self.total += 1

    def report(
        self,
        test: str,
        status: str,
        timestamp: float,
        elapsed: float
    ):
        if test is None:
            self.elapsed = elapsed
            self.timestamp = timestamp
            return

        elif self.timeout and elapsed:
            # see golang src/testing/testing.go
            # last test gets a chance to get duration.
            self.elapsed = elapsed

        self.get_test_builder(test).report(status, timestamp, elapsed)

    def get_test_builder(self, test: str) -> TestBuilder:
        if test not in self.test_builders:
            self.test_builders[test] = TestBuilder(test)
        return self.test_builders[test]

    def build_tests(self):
        tests = sorted(
            (tb.build() for tb in self.test_builders.values()),
            key=lambda t: t.name
        )
        for test in tests:
            self.counts[test.status] += 1
        return tests

    def add_output(self, test, line):
        # super weird timeout handling.
        # see golang src/testing/testing.go
        if line.startswith(TIMEOUT_MESSAGE):
            self.timeout = True
        elif line.startswith(PANIC_MESSAGE):
            self.panic = True

        if test is None:
            self.lines.append(line)
            return

        self.get_test_builder(test).add_output(line)


# Global state.
TESTSUITES = defaultdict(Testsuite)

#
# Handlers for the different go test2json TestEvents.
#


def debug_event(event):
    pprint.pprint(event)


def report_test(status, event):
    package = event.get('Package')
    test = event.get('Test')
    elapsed = event.get('Elapsed')
    timestamp = event.get('Time')
    testsuite = TESTSUITES[package]
    testsuite.report(test, status, timestamp, elapsed)


def action_fail(event):
    report_test(FAIL, event)


def action_output(event):
    package = event.get('Package')
    test = event.get('Test')
    time = event.get('Time', '')
    output = event['Output']
    testsuite = TESTSUITES[package]
    testsuite.add_output(test, output)

    time = time[:24].replace('T', ' ')
    time = '-timeout-' if testsuite.timeout else time
    if 'Test' in event:
        test = event['Test']
        print('{:^24s}  ┃ {}'.format(time, event['Output']), end='')
    else:
        print('{:^24s} ❚┃ {}'.format(time, event['Output']), end='')


def action_pass(event):
    report_test(PASS, event)


def action_run(event):
    package = event.get('Package')
    test = event.get('Test')
    # time = event.get('Time')
    testsuite = TESTSUITES[package]
    testsuite.run(test)


def action_skip(event):
    report_test(SKIP, event)


def broken_test(line):
    print('{:^24s} ❚┃ {}'.format("BROKEN TEST", line), end='')
    # line = "FAIL\tsome/pkg/name [build failed]"
    package = line.replace('FAIL\t', '').replace(' [build failed]\n', '')
    testsuite = TESTSUITES[package]
    test = '[build failed]'
    testsuite.add_output(test, line)
    testsuite.report(test, PANIC, None, None)


# Map TestEvent to its handler.
ACTIONS = {
    'fail': action_fail,
    'output': action_output,
    'pass': action_pass,
    'run': action_run,
    'skip': action_skip,
}


def collect_results_and_print_formatted_line(line):
    """
    This function has 2 purposes:
    1. provide user-friendly output by formatting the go test2json TestEvent.
    2. collecting test results in global state, in `TESTSUITES`.
    """
    line = line.strip()
    # do not parse empty lines
    if not line:
        return
    try:
        event = json.loads(line)
        action = event['Action']
        ACTIONS.get(action, debug_event)(event)
    except (ValueError, KeyError):
        if line.startswith('FAIL\t') and '[build failed]' in line:
            broken_test(line)
        else:
            print('[ParseErr]', line, end='')


def print_summary_and_write_junit_report():
    """
    This function has 2 purposes:
    1. provide user-friendly summary on the console.
    2. generate the machine-readable junit report.

    This is achieved by using global state in `TESTSUITES`.
    """

    print_report_header()

    doc = Document()
    testsuites = doc.createElement('testsuites')
    doc.appendChild(testsuites)

    # top level counters
    total, counts = 0, Counter()

    # Go has concept of packages, whereas junit has concept of testsuites.
    for package in sorted(TESTSUITES.keys()):
        suite = TESTSUITES[package]
        testsuite = doc.createElement('testsuite')
        testsuites.appendChild(testsuite)
        add_junit_elements_for_testsuite(suite, package, testsuite, doc)

        # Wrap package results in a block, e.g.:
        #
        # ┏━━━━━━━━━━━ name-of-the-package
        # ┃ ✅ PASS    0.000s  MyTestCase
        # ┗━━━━━━━━━━━ total=1 passed=1 failed=0 skipped=0 duration=0.014s
        #
        print('┏{} {}'.format('━' * 11, package))  # Begin

        tests = suite.build_tests()
        for case in tests:
            add_junit_elements_for_testcase(case, case.name, testsuite, doc)
            elapsed = case.elapsed if case.elapsed else 0.
            status = case.status if case.status else FAIL

            print('┃ {} {:7} {:8.3f}s  {}'.format(SYMBOLS.get(status, ' '),
                                                  status, elapsed, case.name))

        print(
            '┗{} total={} passed={} failed={} flaky={} skipped={} duration={}\n'.format(
                '━' * 11,
                suite.total,
                suite.counts[PASS],
                suite.counts[FAIL],
                suite.counts[FLAKY],
                suite.counts[SKIP],
                '{:.3f}s'.format(suite.elapsed)
                if suite.elapsed else '{} {}'.format(SYMBOLS[PANIC], PANIC) if
                suite.panic else '{} {}'.format(SYMBOLS[TIMEOUT], TIMEOUT) if
                suite.timeout else '[no tests]' if not suite.total else '???',
            ))  # End.

        total += suite.total
        counts.update(suite.counts)

    print_totals(counts, total)
    write_junit_report_xml(doc)


def add_junit_elements_for_testsuite(suite: Testsuite, package, testsuite,
                                     doc):
    testsuite.setAttribute('name', package)
    testsuite.setAttribute('tests', str(suite.total))
    testsuite.setAttribute('timestamp', suite.timestamp)
    testsuite.setAttribute('failures', str(suite.counts[FAIL]))
    testsuite.setAttribute('skipped', str(suite.counts[SKIP]))

    # case 1: suite ran normally.
    if suite.elapsed:
        testsuite.setAttribute('time', '{:.3f}'.format(suite.elapsed))

    # case 2: go test interrupted the suite due to timeout.
    if suite.timeout:
        testsuite.setAttribute('errors', str(1))
        stderr = doc.createElement('system-err')
        text = doc.createTextNode('TIMEOUT detected')
        stderr.appendChild(text)
        testsuite.appendChild(stderr)

    # case 3: go test interrupted the suite due to other critical error.
    elif suite.panic:
        testsuite.setAttribute('errors', str(1))
        stderr = doc.createElement('system-err')
        text = doc.createTextNode('PANIC detected')
        stderr.appendChild(text)
        testsuite.appendChild(stderr)

    testsuite.setAttribute('name', package)
    if suite.lines:
        stdout = doc.createElement('system-out')
        testsuite.appendChild(stdout)
        _createCDATAsections(doc, stdout, ''.join(suite.lines))


def add_junit_elements_for_testcase(case: Testcase, name, testsuite, doc):
    testcase = doc.createElement('testcase')
    testsuite.appendChild(testcase)
    testcase.setAttribute('name', name)
    if case.elapsed is not None:
        testcase.setAttribute('time', '{:.3f}'.format(case.elapsed))
    if case.timestamp:
        testcase.setAttribute('timestamp', case.timestamp)
    if case.status:
        testcase.setAttribute('status', case.status)
    if case.status == SKIP:
        skip = doc.createElement('skipped')
        skip.setAttribute('message', 'test was skipped')
        testcase.appendChild(skip)
    elif case.status == FAIL:
        fail = doc.createElement('failure')
        fail.setAttribute('message', 'test failed')
        testcase.appendChild(fail)
    elif case.status == TIMEOUT:
        error = doc.createElement('error')
        error.setAttribute('message', 'timeout')
        testcase.appendChild(error)
    elif case.status == PANIC:
        error = doc.createElement('error')
        error.setAttribute('message', 'panic')
        testcase.appendChild(error)
    elif case.status == PASS:
        pass
    else:
        # default to error, e.g. issue with test framework.
        error = doc.createElement('error')
        error.setAttribute(
            'message', 'test did not explicitly pass. please check the logs.')
        testcase.appendChild(error)
    if case.lines:
        stdout = doc.createElement('system-out')
        testcase.appendChild(stdout)
        _createCDATAsections(doc, stdout, ''.join(case.lines))


def print_report_header():
    """
    Provide a nice header easy to spot in test output.
    """

    print('\n┏┳{}'.format('━' * 80))
    print('┃┃ TEST Report')
    print('┗┻{}\n'.format('━' * 80))


def print_totals(counts, total):
    """
    Summarize top level counts, e.g.

    ┏┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ┃┃ TEST totals:
    ┃┃ 📊 TOTAL   = 107 tests
    ┃┃ ✅ PASS    = 105
    ┃┃ ❌ FAIL    = 1
    ┃┃ 🔥 PANIC   = 1
    ┗┻━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    """

    print('┏┳{}'.format('━' * 80))
    print('┃┃ TEST totals:')
    print('┃┃ {} {:7} = {} tests'.format('📊', 'TOTAL', total))
    for name, symbol in SYMBOLS.items():
        if not counts[name]:
            continue
        print('┃┃ {} {:7} = {}'.format(symbol, name, counts[name]))
    print('┗┻{}\n'.format('━' * 80))


def _createCDATAsections(doc, node, text):
    pos = text.find(']]>')
    while pos >= 0:
        tmp = text[0:pos + 2]
        cdata = doc.createCDATASection(tmp)
        node.appendChild(cdata)
        text = text[pos + 2:]
        pos = text.find(']]>')
    # ANSI escape sequences are not valid in XMLs. Below regex finds and replaces them with an empty string
    ansi_escape = re.compile(r'(\x9B|\x1B\[)[0-?]*[ -/]*[@-~]')
    text = ansi_escape.sub('', text)
    cdata = doc.createCDATASection(text)
    node.appendChild(cdata)


def write_junit_report_xml(doc):
    content = doc.toprettyxml()
    try:
        os.makedirs(os.path.dirname(TEST_REPORT_FILE), exist_ok=True)
        with open(TEST_REPORT_FILE, 'wb') as junit:
            junit.write(content.encode('utf-8', errors='surrogateescape'))
    except Exception as e:
        print('Could not write {}: {}\n'.format(TEST_REPORT_FILE, e))
        sys.exit(1)
    print('Successfully wrote {}\n'.format(TEST_REPORT_FILE))


def write_failed_tests_file(args):
    failed_tests = set()
    for _package, suite in sorted(TESTSUITES.items(), key=lambda i: i[0]):
        tests = suite.build_tests()

        for t in tests:
            if t.status == SKIP or t.status == PASS:
                continue
            if args.keep_subtests:
                if '/' in t.name:
                    failed_tests.add(t.name)
                # else it's a top level test, we don't need to add it, there will never be a case where a top level-
                # -fails but no subtests fails a top level test can only fail if at least one of the subtest
                # fails, and we just want to capture that
            else:
                failed_tests.add(t.name[:t.name.index('/')] if '/' in t.name else t.name)
    failed_tests_str = "|".join(failed_tests)
    if CI:
        print(f"writing '{failed_tests_str}' to file '{FAILED_TESTS}'")
        try:
            os.makedirs(os.path.dirname(FAILED_TESTS), exist_ok=True)
            with open(FAILED_TESTS, "w") as f:
                f.write(failed_tests_str)
        except FileNotFoundError:
            print("failed to write failed tests, file doesn't exist and couldn't be written two")
    elif failed_tests_str:
        print(f"to rerun tests that failed, run your go test command with -run '{failed_tests_str}'")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-k", "--keep_subtests", default=False, action="store_true",
                        help="keep subtests in failed tests file")
    parser.add_argument('files', metavar='FILE', nargs='*', help='files to read, if empty, stdin is used')
    args = parser.parse_args()

    for line in fileinput.input(files=args.files):
        collect_results_and_print_formatted_line(line)

    print_summary_and_write_junit_report()
    write_failed_tests_file(args)
