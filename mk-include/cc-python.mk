INIT_CI_TARGETS += python-deps
TEST_TARGETS += python-lint python-test

PYTHON_VERSION ?= 3.7
PIPENV_VERSION ?= 2020.11.15

PYTEST ?= pipenv run python -m pytest
PYTEST_ARGS ?=
PYTEST_IGNORE_DIR = mk-include
 # You can also use pytest.ini to ignore if you overwrite pytest cmds
PYTEST_ARGS += --ignore=$(PYTEST_IGNORE_DIR)
 # include arguments to generate coverage 
ifeq ($(RUN_COVERAGE), true)
PYTEST_ARGS += --cov --cov-report=xml --cov-report=html --cov-report=term --cov-report=annotate:textcov
endif
 # If we don't specify this, fails on any suggestions, even conventions (lower than warnings)
PYLINT_ARGS ?= --fail-under 9.0 --fail-on F,E

DOCKER_BUILD_OPTIONS += --build-arg pipenv_version=$(PIPENV_VERSION)

 # Ignore any active virtualenv and use the pipenv managed virtualenv instead
PIPENV_IGNORE_VIRTUALENVS ?= 1
export PIPENV_IGNORE_VIRTUALENVS

.PHONY: python-install-linters
## Add and Install Python linters to Pipfile
python-install-linters:
	pipenv install --python $(PYTHON_VERSION) yapf flake8 isort pytest pylint pytest-cov --dev

.PHONY: python-resources
python-resources:
	cp $(MK_INCLUDE_RESOURCE)/.flake8 ./.flake8
	cp $(MK_INCLUDE_RESOURCE)/.style.yapf ./.style.yapf
	cp $(MK_INCLUDE_RESOURCE)/.yapfignore ./.yapfignore
	cp $(MK_INCLUDE_RESOURCE)/.pylintrc ./.pylintrc
	cp $(MK_INCLUDE_RESOURCE)/.isort.cfg ./.isort.cfg

.PHONY: python-deps
## Setup the python env with dependencies
python-deps:
	pip install pipenv==$(PIPENV_VERSION)
	pipenv install --python $(PYTHON_VERSION) --dev

.PHONY: python-lint
## Lint the python code against project standards
python-lint:
	pipenv run yapf -rd .
	pipenv run flake8 .
	find . -path ./mk-include -prune -false -o -iname '*.py' | xargs pipenv run pylint $(PYLINT_ARGS)  # to lint a dir it must be a python module; instead run file-by-file
	pipenv run isort --check-only .

.PHONY: python-fmt
## Format the python code to follow the project standards
python-fmt:
	pipenv run yapf -ir .
	pipenv run isort .

.PHONY: python-test
## Run all python tests (pytest)
python-test:
	$(PYTEST) $(PYTEST_ARGS)
