TEST_RESULT_FILE_NAME ?= $(SEMAPHORE_PIPELINE_ID)-TEST-result.xml
TEST_RESULT_FILE ?= $(BUILD_DIR)/$(TEST_RESULT_FILE_NAME)

GO_COVERAGE_HTML ?= coverage.html
COVERAGE_REPORT_URL := $(SEMAPHORE_ORGANIZATION_URL)/jobs/$(SEMAPHORE_JOB_ID)/artifacts/$(GO_COVERAGE_HTML)

ifeq ($(SEMAPHORE_2),true)
# In Semaphore 2, the cache must be manually managed.
# References:
#   https://docs.semaphoreci.com/article/68-caching-dependencies
#   https://docs.semaphoreci.com/article/54-toolbox-reference#cache

INIT_CI_TARGETS += ci-bin-sem-cache-restore
EPILOGUE_TARGETS += ci-bin-sem-cache-store store-test-results-to-semaphore
DEB_CACHE_DIR ?= $(SEMAPHORE_CACHE_DIR)/.deb-cache
PIP_CACHE_DIR ?= $(shell pip3 cache dir)
CI_BIN_OVERRIDE ?= ci-bin

ifeq ($(SEMAPHORE_GIT_PR_BRANCH),)
    CACHE_KEY = ci-bin_$(SEMAPHORE_GIT_BRANCH)
else
    CACHE_KEY = ci-bin_$(SEMAPHORE_GIT_PR_BRANCH)
endif

.PHONY: ci-bin-sem-cache-store
ci-bin-sem-cache-store:
	@echo "Storing semaphore caches"
	cache delete $(CACHE_KEY) \
		&& cache store $(CACHE_KEY) $(CI_BIN_OVERRIDE)
	# For most repos, these caches are very large, so don't delete
	# and restore them. In the (rare) case that the caches are corrupted 
	# we should just clear them manually in semaphore 
	cache store gocache $(GOPATH)/pkg/mod
	cache store pip3_cache $(PIP_CACHE_DIR)
	cache store install_package_cache $(DEB_CACHE_DIR)

.PHONY: ci-bin-sem-cache-restore
ci-bin-sem-cache-restore:
	@echo "Restoring semaphore caches"
	cache restore $(CACHE_KEY),ci-bin_master,ci-bin
	cache restore gocache
	cache restore pip3_cache
	cache restore install_package_cache

.PHONY: ci-bin-sem-cache-delete
ci-bin-sem-cache-delete:
	@echo "Deleting semaphore caches"
	cache delete $(CACHE_KEY)
endif

.PHONY: ci-generate-and-store-coverage-data
ci-generate-and-store-coverage-data: $(GO_COVERAGE_HTML) print-coverage-out
	artifact push job $(GO_COVERAGE_HTML)

.PHONY: ci-coverage
ci-coverage: ci-generate-and-store-coverage-data go-gate-coverage
	@echo "find coverate report at: $(COVERAGE_REPORT_URL)"

.PHONY: store-test-results-to-semaphore
store-test-results-to-semaphore:
ifneq ($(wildcard $(TEST_RESULT_FILE)),)
ifeq ($(TEST_RESULT_NAME),)
	test-results publish $(TEST_RESULT_FILE)
else
	test-results publish $(TEST_RESULT_FILE) --name "$(TEST_RESULT_NAME)"
endif
else
	@echo "test results not found at $(TEST_RESULT_FILE)"
endif
