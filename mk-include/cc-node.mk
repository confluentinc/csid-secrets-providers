DOCKER_BUILD_PRE  += .npmrc
DOCKER_BUILD_POST += clean-npmrc
RELEASE_PRECOMMIT += set-node-bumped-version

NPM_REPOSITORY ?= npm-internal
NPM_SCOPE ?= @confluent

.PHONY: set-node-bumped-version
set-node-bumped-version:
	test -f package.json \
		&& (npm version $(BUMPED_VERSION) --git-tag-version=false &&\
			git add package.json) \
		|| true

.npmrc: $(HOME)/.npmrc
	cp $(HOME)/.npmrc .npmrc

clean-npmrc:
	rm .npmrc

# DEVPROD_PROD_AWS_ACCOUNT is defined in cc-begin.mk
$(HOME)/.npmrc:
ifneq ($(NPM_SCOPE),$(_empty))
	@aws codeartifact login \
		--tool npm \
		--domain confluent \
		--domain-owner $(DEVPROD_PROD_AWS_ACCOUNT) \
		--region us-west-2 \
		--repository $(NPM_REPOSITORY) \
		--namespace $(NPM_SCOPE) \
	2> /dev/null || echo "Unable to configure $@ for codeartifact access"
else
	@aws codeartifact login \
		--tool npm \
		--domain confluent \
		--domain-owner $(DEVPROD_PROD_AWS_ACCOUNT) \
		--region us-west-2 \
		--repository $(NPM_REPOSITORY) \
	2> /dev/null || echo "Unable to configure $@ for codeartifact access"
endif

.PHONY: npm-login
## Login to Confluent's private npm on CodeArtifact
npm-login: $(HOME)/.npmrc
