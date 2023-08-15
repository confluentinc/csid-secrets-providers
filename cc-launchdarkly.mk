# The 'run-ld-find-code-refs' target defined here will generate LaunchDarkly flag code 
# references and upload them to LaunchDarkly, which can then be found against each flag.
# Before running this target, inject the credentials found in v1/ci/kv/service-foundations/cc-mk-include
# The code refs searches for extinctions only looking back one commit. Hence, this tool works best
# when the PR is squashed into a single commit when merging to master/main branches.

BUILD_TARGETS += run-ld-find-code-ref

ifeq ($(SEMAPHORE_GIT_PR_BRANCH),)
	GIT_BRANCH_NAME_LD = $(SEMAPHORE_GIT_BRANCH)
else
	GIT_BRANCH_NAME_LD = $(SEMAPHORE_GIT_PR_BRANCH)
endif

# (TODO) [SVCF-4416] Change to latest after
# https://github.com/launchdarkly/ld-find-code-refs/issues/378 is fixed
LD_FIND_CODE_REFS_VERSION ?= v2.10.0

ifeq ($(LD_FIND_CODE_REFS_VERSION),latest)
LD_FIND_CODE_REFS_RELEASE_URL := https://api.github.com/repos/launchdarkly/ld-find-code-refs/releases/latest
else
LD_FIND_CODE_REFS_RELEASE_URL := https://api.github.com/repos/launchdarkly/ld-find-code-refs/releases/tags/$(LD_FIND_CODE_REFS_VERSION)
endif

.PHONY: show-launchdarkly
show-launchdarkly:
	@echo "GIT_BRANCH_NAME_LD: $(GIT_BRANCH_NAME_LD)"
	@echo "SEMAPHORE_PROJECT_NAME: $(SEMAPHORE_PROJECT_NAME)"
	@echo "SEMAPHORE_GIT_REPO_SLUG: $(SEMAPHORE_GIT_REPO_SLUG)"
	@echo "LD_FIND_CODE_REFS_VERSION: $(LD_FIND_CODE_REFS_VERSION)"
	@echo "LD_FIND_CODE_REFS_RELEASE_URL: $(LD_FIND_CODE_REFS_RELEASE_URL)"

# Download and install the 'ld-find-code-refs' CLI
.PHONY: install-ld-find-code-refs
install-ld-find-code-refs:
ifeq ($(CI),true)
	wget -qO- $(LD_FIND_CODE_REFS_RELEASE_URL) \
	| grep "browser_download_url" \
	| grep "amd64.deb" \
	| cut -d'"' -f4 \
	| wget -qi - -O ld-find-code-refs.amd64.deb \
	&& sudo dpkg -i ld-find-code-refs.amd64.deb \
	&& rm ld-find-code-refs.amd64.deb 2>&1 >/dev/null
endif

# Generate and upload the code references. Docs for the CLI can be found at its github 
# homepage: https://github.com/launchdarkly/ld-find-code-refs
.PHONY: run-ld-find-code-refs
run-ld-find-code-ref: install-ld-find-code-refs
ifeq ($(CI),true)
	@ld-find-code-refs --debug --branch $(GIT_BRANCH_NAME_LD) --dir=. --repoName $(SEMAPHORE_PROJECT_NAME) \
	--repoUrl https://github.com/$(SEMAPHORE_GIT_REPO_SLUG) \
	--projKey default --accessToken $(LD_ACCESS_TOKEN) --lookback 1 2>&1
endif
