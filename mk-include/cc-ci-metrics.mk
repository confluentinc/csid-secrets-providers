GIT_SHA ?= $(SEMAPHORE_GIT_SHA)
GIT_REPO ?= $(SEMAPHORE_GIT_REPO_SLUG)

ifeq ($(BRANCH_NAME),$(MASTER_BRANCH))
ifeq ($(CI),true)
RELEASE_POSTCOMMIT += send-version-bump-event
endif
endif

.PHONY: pip-install-dependencies
pip-install-dependencies:
ifeq ($(BRANCH_NAME),$(MASTER_BRANCH))
ifeq ($(CI),true)
	pip3 install confluent-ci-tools
	@if [ -d ".halyard" ]; then \
		pip3 install pyyaml==6.0; \
	fi
endif
endif

.PHONY: send-version-bump-event
send-version-bump-event: pip-install-dependencies
ifeq ($(BRANCH_NAME),$(MASTER_BRANCH))
ifeq ($(CI),true)
	@if [ -d ".halyard" ]; then \
		for service in $(shell python3 $(MK_INCLUDE_BIN)/parse_service_names.py .halyard); do \
			echo "Reporting version bump event for $(GIT_REPO):$(BUMPED_VERSION) ($$service)"; \
			ci-version-bump-event --repo $(GIT_REPO) --commit $(GIT_SHA) --bumped-version $(BUMPED_VERSION) --service $$service; \
		done; \
	else \
		echo "Reporting version bump event for $(GIT_REPO):$(BUMPED_VERSION)"; \
		ci-version-bump-event --repo $(GIT_REPO) --commit $(GIT_SHA) --bumped-version $(BUMPED_VERSION); \
	fi
endif
endif
