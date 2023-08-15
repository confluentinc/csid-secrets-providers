import argparse
import json
import os
import subprocess
import sys
from collections import defaultdict

import yaml

# From: https://github.com/stoplightio/types/blob/master/src/diagnostics.ts
severity_to_name = {0: "error", 1: "warning", 2: "info", 3: "hint"}


def collect_input():
    input = sys.stdin.readlines()
    parsedJson = json.loads("".join(input))

    return parsedJson


def parse_linter_metrics(input, api_name):

    counts = defaultdict(int)
    severity = {}

    # JSON is an array of rule violations
    for violation in input:

        counts[violation["code"]] += 1
        severity[violation["code"]] = severity_to_name[violation["severity"]]

    metrics = []
    for rule in counts:
        metrics.append({
            "metric": f"openapi_linter.{severity[rule]}s",
            "points": [counts[rule]],
            "tags": [f"api:{api_name}", f"rule:{rule}"]
        })

    return metrics


def parse_exception_metrics(api_exceptions_filename, api_name):

    counts = defaultdict(int)

    stream = open(api_exceptions_filename, 'r')
    parsed = yaml.safe_load(stream)

    metrics = []

    # Post metrics for any turned off rules
    for rule, enabled in parsed.get("rules", {}).items():
        if not enabled:
            metrics.append({
                "metric": "openapi_linter.disabled_rules",
                "points": [1],
                "tags": [f"api:{api_name}", f"rule:{rule}"]
            })

    for rules in parsed.get("except", {}).values():
        for rule in rules:
            counts[rule] += 1

    for rule in counts:
        metrics.append({
            "metric": "openapi_linter.exceptions",
            "points": [counts[rule]],
            "tags": [f"api:{api_name}", f"rule:{rule}"]
        })

    return metrics


def format_range(range):
    # Spectral JSON formatter returns 0-indexed line/character numbers, so add 1
    return f"{range['start']['line'] + 1}:{range['start']['character'] + 1}"


def format_path(segments):
    if len(segments) == 0:
        return '#'

    return "#/" + "/".join(segments)


def format_counts(count, word):
    return f"{count} {word + ('s' if count != 1 else '')}"


def print_output(input):

    # Newline for formatting
    print()
    if len(input) == 0:
        print("No linter violations found! ✅")
        return

    counts = [0] * len(severity_to_name)
    for violation in input:
        print("{:<8} {:<8} {:<25} {:<20} {:<20}".format(
            format_range(violation['range']),
            severity_to_name[violation['severity']], violation['code'],
            violation['message'], format_path(violation['path'])))
        counts[violation['severity']] += 1

    summary = ", ".join([
        format_counts(counts[severity], name)
        for (severity, name) in severity_to_name.items()
    ])
    print(f"\n❌ {format_counts(sum(counts), 'violation')} ({summary})")


def post_metrics(metrics):
    import datadog
    datadog.initialize()

    res = datadog.api.Metric.send(metrics)


def isFileChanged(api_spec_filename):

    command = f"git diff --name-only `git merge-base master HEAD` | grep -v ccloud/openapi.yaml | grep ${api_spec_filename}"
    output = subprocess.run(command, shell=True, capture_output=True).stdout

    return len(output) != 0


def main():

    parser = argparse.ArgumentParser(
        description="Report OpenAPI linting metrics to Datadog.")
    parser.add_argument(
        "api_name",
        help="the short name of the API that metrics are associated with")
    parser.add_argument("api_spec_filename",
                        help="path to the OpenAPI spec that was linted")

    # Since these arguments are optional, they need to be specified via flags
    parser.add_argument(
        "--exceptions",
        "-e",
        help=
        "path to a Spectral ruleset file defining linting exceptions, if any")
    parser.add_argument("--submit-metrics",
                        action='store_true',
                        help="enable posting metrics to datadog",
                        default=os.environ.get('CI', False))
    parser.add_argument("--debug",
                        action='store_true',
                        help="enable debugging mode",
                        default=os.environ.get('DEBUG', False))
    args = parser.parse_args()

    input = collect_input()

    print_output(input)

    if (len(input) == 0
            or not isFileChanged(args.api_spec_filename)) and not args.debug:
        return

    linter_metrics = parse_linter_metrics(input, args.api_name)

    exception_metrics = []
    if args.exceptions:
        exception_metrics = parse_exception_metrics(args.exceptions,
                                                    args.api_name)

    metrics = linter_metrics + exception_metrics
    if args.debug:
        print(json.dumps(metrics, indent=2))
    # Don't submit metrics if we're in debug mode since we don't want to mess up our counts/averages/etc
    if args.submit_metrics and not args.debug:
        post_metrics(metrics)


if __name__ == "__main__":
    main()
