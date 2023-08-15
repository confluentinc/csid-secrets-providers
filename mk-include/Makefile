DOCKER_GO_TEST_LOCATION := tests/go-docker-build-test/
DOCKER_MULTIARCH_TEST_LOCATION := tests/multiarch-docker-build-test/
MK_INCLUDE_AUTO_UPDATE_TEST_LOCATION := tests/mk-include-auto-update-test/
MAVEN_DOCKER_BUILD_TEST := tests/maven-docker-build-test/
MK_INCLUDE_SANITY_IMPORT_TEST_LOCATION := tests/sanity-import-test/
MK_INCLUDE := mk-include/
UPDATE_MK_INCLUDE := false
CC_MK_INCLUDE := cc-mk-include

include ./cc-begin.mk
include ./cc-vault.mk
include ./cc-semver.mk
include ./cc-ci-metrics.mk
include ./cc-pact.mk
include ./cc-sonarqube.mk
include ./cc-testbreak.mk
include ./cc-end.mk

.PHONY: copy-mk-include-install-pact-tools-script
copy-mk-include-install-pact-tools-script:
	cp ./bin/install-pact-tools.sh ${MK_INCLUDE}bin

.PHONY: copy-mk-include-multiarch-docker-build-test
copy-mk-include-multiarch-docker-build-test:
	find . -name '*.mk' | cpio -pdm "${DOCKER_MULTIARCH_TEST_LOCATION}""${MK_INCLUDE}"
	cp -R bin/. "${DOCKER_MULTIARCH_TEST_LOCATION}""${MK_INCLUDE}""bin"
	cp .gitignore "${DOCKER_MULTIARCH_TEST_LOCATION}"

.PHONY: copy-mk-include-go-docker-build-test
copy-mk-include-go-docker-build-test:
	find . -name '*.mk' | cpio -pdm "${DOCKER_GO_TEST_LOCATION}""${MK_INCLUDE}"
	cp -R bin/. "${DOCKER_GO_TEST_LOCATION}""${MK_INCLUDE}""bin"
	cp .gitignore "${DOCKER_GO_TEST_LOCATION}"

.PHONY: copy-mk-include-mk-include-auto-update-test
copy-mk-include-mk-include-auto-update-test:
	find . -name '*.mk' | cpio -pdm "${MK_INCLUDE_AUTO_UPDATE_TEST_LOCATION}""${MK_INCLUDE}"
	cp -R bin "${MK_INCLUDE_AUTO_UPDATE_TEST_LOCATION}""${MK_INCLUDE}"
	cp .gitignore "${MK_INCLUDE_AUTO_UPDATE_TEST_LOCATION}"

.PHONY: copy-mk-include-maven-docker-build-test
copy-mk-include-maven-docker-build-test:
	find . -name '*.mk' | cpio -pdm "${MAVEN_DOCKER_BUILD_TEST}""${MK_INCLUDE}"
	cp -R bin "${MAVEN_DOCKER_BUILD_TEST}""${MK_INCLUDE}"

.PHONY: copy-mk-include-sanity-import-test
copy-mk-include-sanity-import-test:
	find . -name '*.mk' | cpio -pdm "${MK_INCLUDE_SANITY_IMPORT_TEST_LOCATION}""${MK_INCLUDE}"
	cp -R bin "${MK_INCLUDE_SANITY_IMPORT_TEST_LOCATION}""${MK_INCLUDE}"
	cp .gitignore "${MK_INCLUDE_SANITY_IMPORT_TEST_LOCATION}"

.PHONY: copy-parent-mk-include
copy-parent-mk-include:
	find . -name '*.mk' | cpio -pdm "${MK_INCLUDE}"
	cp -R bin/. "${MK_INCLUDE}""bin"

.PHONY: upload-binary
upload-binary:
	cd .. ;\
	tar --exclude='$(CC_MK_INCLUDE)/.git' --exclude='$(CC_MK_INCLUDE)/.semaphore' \
	--exclude='$(CC_MK_INCLUDE)/tests' --exclude='$(CC_MK_INCLUDE)/.DS_Store' \
	--exclude='$(CC_MK_INCLUDE)/mk-include' --exclude='$(CC_MK_INCLUDE)/ci-bin' \
	-zcvf $(CC_MK_INCLUDE)_$(BUMPED_VERSION).tar.gz $(CC_MK_INCLUDE) ;\
	aws s3 cp $(CC_MK_INCLUDE)_$(BUMPED_VERSION).tar.gz s3://$(CC_MK_INCLUDE) ;\
	cp $(CC_MK_INCLUDE)_$(BUMPED_VERSION).tar.gz $(CC_MK_INCLUDE)_master.tar.gz ;\
	aws s3 cp $(CC_MK_INCLUDE)_master.tar.gz s3://$(CC_MK_INCLUDE) ;

.PHONY: verify-version
verify-version:
	@[[ "$(VERSION)" =~ ^v[0-9]+\.[0-9]+\.([0-9]+$$|[0-9]+-[0-9]+-[a-zA-Z0-9]+$$) ]] && echo "version format verified"
