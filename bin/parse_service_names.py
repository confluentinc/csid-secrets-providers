#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
This command line script takes path to Halyard configs as an input and extracts all
service names associated with the project/repo from config files (yaml) and prints
the set of service names. This is consumed in cc-ci-metrics.mk for reporting version
bump events

* Require PyYAML (pip install PyYAML)
"""

import argparse
import pathlib

import yaml


def main(config_path):
    service_names = set()
    path = pathlib.Path(config_path)
    if path.exists() and path.is_dir():
        for config_file in path.glob("**/*.yaml"):
            with open(config_file, 'r') as cf:
                config = yaml.safe_load(cf)
                service_names.add(config['data']['name'])
    print(' '.join(sorted(list(service_names))))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Parse service names from Halyard config files')
    parser.add_argument('config_path',
                        type=str,
                        help='Path to Halyard configs')
    args = parser.parse_args()
    main(args.config_path)
