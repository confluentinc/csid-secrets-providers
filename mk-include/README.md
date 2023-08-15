# Confluent Cloud Makefile Includes
This is a set of Makefile include targets that are used in cloud applications.

Repo Structure:
*  All makefiles related are maintained by dev prod team
*  [`/seed-db/`](./seed-db) includes mothership db seed files are maintained by ccloud and connect-cloud

The purpose of cc-mk-include is to present a consistent developer experience across repos/projects:
```
make deps
make build
make test
make clean
```

It also helps standardize our CI pipeline across repos:
```
make init-ci
make build
make test
make release-ci
make epilogue-ci
```

## Install
Add this repo to your repo with the command:
```shell
git subtree add --prefix mk-include git@github.com:confluentinc/cc-mk-include.git master --squash
```

To exclude these makefiles from your project language summary on GitHub, add this to your `.gitattributes`:
```
mk-include/** linguist-vendored
```

Then update your makefile like so:

### Go + Docker + Helm Service
```make
SERVICE_NAME := scraper
CHART_NAME := cc-$(SERVICE_NAME)
IMAGE_NAME := cc-$(SERVICE_NAME)
GO_BINS := cmd/scraper/main.go=cc-scraper

include ./mk-include/cc-begin.mk
include ./mk-include/cc-semver.mk
include ./mk-include/cc-go.mk
include ./mk-include/cc-docker.mk
include ./mk-include/cc-cpd.mk
include ./mk-include/cc-helm.mk
include ./mk-include/cc-testbreak.mk
include ./mk-include/cc-vault.mk
include ./mk-include/cc-end.mk
```

### Docker + Helm Only Service
```make
IMAGE_NAME := cc-example
CHART_NAME := $(IMAGE_NAME)

include ./mk-include/cc-begin.mk
include ./mk-include/cc-semver.mk
include ./mk-include/cc-docker.mk
include ./mk-include/cc-cpd.mk
include ./mk-include/cc-helm.mk
include ./mk-include/cc-end.mk
```

### Java (Maven) + Docker + Helm Service

#### Maven-orchestrated Docker build
```make
IMAGE_NAME := cc-java-example
CHART_NAME := cc-java-example
BUILD_DOCKER_OVERRIDE := mvn-docker-package

include ./mk-include/cc-begin.mk
include ./mk-include/cc-semver.mk
include ./mk-include/cc-maven.mk
include ./mk-include/cc-docker.mk
include ./mk-include/cc-cpd.mk
include ./mk-include/cc-helm.mk
include ./mk-include/cc-end.mk
```

#### Make-orchestrated Docker build
```make
IMAGE_NAME := cc-java-example
CHART_NAME := cc-java-example
MAVEN_INSTALL_PROFILES += docker

build-docker: mvn-install

include ./mk-include/cc-begin.mk
include ./mk-include/cc-semver.mk
include ./mk-include/cc-maven.mk
include ./mk-include/cc-docker.mk
include ./mk-include/cc-cpd.mk
include ./mk-include/cc-helm.mk
include ./mk-include/cc-end.mk
```

In this scenario, the `docker` profile from `io.confluent:common` is leveraged to assemble the filesystem layout
for the Docker build.  However, `cc-docker.mk` is used to invoke the actual `docker build` command.

You must also configure your project's `pom.xml` to skip the `dockerfile-maven-plugin`:
```xml
  <properties>
    <docker.skip-build>false</docker.skip-build>
  </properties>
  <profiles>
    <profile>
      <id>docker</id>
      <build>
        <plugins>
          <!--
          Skip dockerfile-maven-plugin since we do the actual docker build from make
          Note that we still leverage the `docker` profile to do the filesystem assembly
          -->
          <plugin>
            <groupId>com.spotify</groupId>
            <artifactId>dockerfile-maven-plugin</artifactId>
            <executions>
              <execution>
                <id>package</id>
                <configuration>
                  <skip>true</skip>
                </configuration>
              </execution>
            </executions>
          </plugin>
        </plugins>
      </build>
    </profile>
  </profiles>
```

## Migrating to separated mk-include checkout
See [Refactor cc-mk-include Deployment](https://confluentinc.atlassian.net/wiki/spaces/TOOLS/pages/3046114540/Refactor+cc-mk-include+deployment)
wiki for the rationale for this change.

Maintaining individual copies of cc-mk-include inside each client project scales badly and makes rolling out changes to 100's of repos unnecessarily time-consuming, and rolling out co-ordinated roll-backs or reverts in a timely fashion impossible.
Following the instructions in this section will enable your project to receive all qualified cc-mk-include releases (and reverts!) within a few hours of release.

First, you will need to disable `cc-mk-include` automatic updates by `cc-service-bot` by adding the following to your top-level `service.yml` configuration:

```yaml
make:
  enable: true
  enable_updates: false
```

`make: enable` will allow service bot to continue to update the managed headers and includes in your `Makefile`, setting it to `false` is fine if you don't want that.  The `make: enable_updates` setting prevents service bot from trying to check in a copy of `cc-mk-include` into the `mk-include/` subdirectory.

Disable `cc-mk-include` self-updates too, by inserting the following before the `Makefile` includes section (usually starts with `### BEGIN INCLUDES ###`, if managed by `cc-service-bot`):

```make
UPDATE_MK_INCLUDE := false
UPDATE_MK_INCLUDE_AUTO_MERGE := false
```

Then, to make sure that any invocation of `make` from CI or engineer laptops keeps the separated `mk-include/` directory updated, add the following to the top-level project `Makefile`:

```make
CURL = curl
FIND = find
SED = sed
TAR = tar

MK_INCLUDE_DIR = mk-include
MK_INCLUDE_TIMEOUT_MINS = 240
MK_INCLUDE_TIMESTAMP_FILE = .mk-include-timestamp

GITHUB_API = https://api.github.com
GITHUB_API_CC_MK_INCLUDE = $(GITHUB_API)/repos/$(GITHUB_OWNER)/$(GITHUB_REPO)
GITHUB_API_CC_MK_INCLUDE_LATEST = $(GITHUB_API_CC_MK_INCLUDE)/releases/latest
GITHUB_OWNER = confluentinc
GITHUB_REPO = cc-mk-include

# Make sure we always have a copy of the latest cc-mk-include release from
# less than $(MK_INCLUDE_TIMEOUT_MINS) ago:
./$(MK_INCLUDE_DIR)/%.mk: .mk-include-check-FORCE
	@test -z "`$(FIND) $(MK_INCLUDE_TIMESTAMP_FILE) -mmin +$(MK_INCLUDE_TIMEOUT_MINS) 2>&1`" || { \
	   $(CURL) --silent --netrc --location $(GITHUB_API_CC_MK_INCLUDE_LATEST) \
	      |$(SED) -n '/"tarball_url"/{s/^.*: *"//;s/",*//;p;q;}' \
	      |xargs $(CURL) --silent --netrc --location --output $(MK_INCLUDE_TIMESTAMP_FILE) \
	   && $(TAR) zxf $(MK_INCLUDE_TIMESTAMP_FILE) \
	   && rm -rf $(MK_INCLUDE_DIR) \
	   && mv $(GITHUB_OWNER)-$(GITHUB_REPO)-* $(MK_INCLUDE_DIR) \
	   && echo installed latest $(GITHUB_REPO) release \
	   ; \
	} || { \
	   echo 'unable to access $(GITHUB_REPO) fetch API to check for latest release; next try in $(MK_INCLUDE_TIMEOUT_MINS) minutes'; \
	   touch $(MK_INCLUDE_TIMESTAMP_FILE); \
	}

.mk-include-check-FORCE:
```

The value of `MK_INCLUDE_TIMEOUT_MINS` controls how often GitHub will be checked for a new `cc-mk-include` release and, if necessary, updated.  The 240 minutes value is fairly arbitrary, but it should be at least as long as a worst case build time in CI to avoud refreshing the `mk-include/` subdirectory part-way through a build.  If your project typically takes much less (or more!) than 4 hours, feel free to set this timeout value accordingly.

For the new section above to work correctly from an engineer laptop, you'll have to ensure the secrets are installed correctly in your `~/.netrc` file in order to enable access to the GitHub REST API, which is used to fetch and install `cc-mk-include` releases.  Instructions for setting up your `.netrc` are available in the wiki: [Setting up Accounts](https://confluentinc.atlassian.net/wiki/spaces/Engineering/pages/1085800848/Setting+up+Accounts#SettingupAccounts-Github)

Similarly, for CI to have access to the GitHub REST API before the `mk-include/vault.mk` rules are available, you'll need to add the same snippet from above to `.semaphore/semaphore.yml` before the first invocation of `make`.  Any subsequent `. vault-sem-get-secret netrc` is unnecessary, and can be removed.

Roll all of the above into a PR, test it and merge to complete migration!

## Updating
**This entire section is superceded by the section above.  You should not need to do anything from here after migrating.**

Once you have the make targets installed, you can update at any time by running

```shell
make update-mk-include
```
### Update to a specific version

Add
```shell
MK_INCLUDE_UPDATE_VERSION := v<version>
```
to you Makefile and commit the change. Then run
```shell
make update-mk-include
```
It will update to that specific tag version of mk-include.

## Auto Update
The cc-mk-include by default auto-sync your repo with the newest or pinned version of cc-mk-include. It will *auto open* a PR if your master branch is not at the same version with newest or pinned version. And it will *auto merged* if the CI passed.
The default sync version will be master branch, you can pin whatever version you want to by enable
```shell
MK_INCLUDE_UPDATE_VERSION := <tag>
```
if you do not want to auto merge the change once CI passed, and get hand on reviews. In your toplevel Makefile, you can set
```shell
UPDATE_MK_INCLUDE_AUTO_MERGE := false
```
If you want to turn off auto update competely
```shell
UPDATE_MK_INCLUDE := false
```

GITHUB token is required for gh cli, so you might need to get the right credentials to export github token.
```
. vault-sem-get-secret semaphore-secrets-global
```

### Auto Merge
Leverage gh cli, cc-mk-include now support auto merge, add
```shell
make auto-merge
```
in the end semaphore.yml, once all CI passed

## Passing Credentials Into A Docker Build

If your docker build requires ssh, aws, netrc, or other credentials to be passed into the
docker build, see [the secrets readme](BuildKitSecrets.md).

## Standardized Dependencies

If you need to install a standardized dependency, just include its file.
```
include ./mk-include/cc-librdkafka.mk
include ./mk-include/cc-sops.mk
```

## OpenAPI Spec
Include `cc-api.mk` for make targets supporting OpenAPI spec development:
```
API_SPEC_DIRS := src/main/resources/openapi

include ./mk-include/cc-api.mk
```
Ensure your CI job includes a `~/.netrc` secret with an `api.github.com` entry
with credentials to post [openapi-linter](https://github.com/confluentinc/openapi-linter)
[warnings as PR comments](https://github.com/confluentinc/cc-mk-include/pull/751/files#diff-c83353d0fb5da910fbeb54df156c929925be7535fe64213f82cf34c9f21913fbR18)
on your github repo.

This integration looks in `API_SPEC_DIRS` for files named `minispec.yaml` and/or `openapi.yaml`.
All generated files are output into the same directory as the input files.

This will automatically integrate into the `build` and `test` top-level make targets:
* [`build` phase] Generate API-related artifacts.
  * Generate OpenAPI specification using Minispec (target: `api-spec` or `openapi`)
  * Generate HTML API documentation using ReDoc (target: `api-docs`)
* [`test` phase] Lint the API spec using:
  * [`yamllint`](https://github.com/adrienverge/yamllint) (target: `api-lint-yaml`)
  * [`openapi-spec-validator`](https://github.com/p1c2u/openapi-spec-validator) (target: `api-lint-openapi-spec-validator`)
  * [`spectral`](https://github.com/stoplightio/spectral) (target: `api-lint-spectral`)
* [`clean` phase] Remove all generated artifacts.

This also provides integration with the following tools:
  * (POC) Lint your API spec using [`speccy`](https://github.com/wework/speccy) (target: `api-lint-speccy`)
  * (POC) Auto-reload API docs using [`redoc-cli`](https://github.com/Redocly/redoc/tree/master/cli) (target: `redoc-serve` or `redoc-start`/`redoc-stop`)
  * (POC) Run a mock API server using [`prism`](https://github.com/stoplightio/prism) (target: `api-mock`)
  * (POC) Generate API load tests using [`gatling`](https://gatling.io/) (target: `api-loadtest`)
  * (POC) Generate Postman collections using [`openapi-to-postmanv2`](https://www.npmjs.com/package/openapi-to-postmanv2) (target: `api-postman`)
  * (POC) Generate SDK in Golang using [`openapi-generator`](https://github.com/OpenAPITools/openapi-generator) (target: `sdk/go`)
  * (POC) Generate SDK in Java using [`openapi-generator`](https://github.com/OpenAPITools/openapi-generator) (target: `sdk/java`)

## Add github templates

To add the github PR templates to your repo

```shell
make add-github-templates
```

## LaunchDarkly Code References

To generate and upload feature flag code references, you can include the `cc-launchdarkly.mk` file in your project Makefile:

```
include ./mk-include/cc-launchdarkly.mk
```

This script will install LaunchDarkly's code ref tool from [github](https://github.com/launchdarkly/ld-find-code-refs), and run it as a release target.

This tool requires API tokens from LaunchDarkly, which are stored in Vault. Include the following line in your Semaphore configuration file (`.semaphore/semaphore.yml`) to add the token as an environment variable:

```
. vault-sem-get-secret v1/ci/kv/service-foundations/cc-mk-include
```

Once this target successfully runs, we can navigate to the Code References tab for a feature flag, and see a list of references to the git codebase that uses this flag.

## Database Plugin and DB Migrations (WIP)

We're developing a runtime-library for go with [cc-go-template-service](https://github.com/confluentinc/cc-go-template-service).
One of the developer productivity improvements is that it allows you to manage your database schema,
migrations, and seed data in your service repo (instead of cc-dbmigrate and cc-mk-include/seed-db).

1. Use the [runtime-library](https://github.com/confluentinc/cc-go-template-service/tree/be480a66bd8172dab089c4779314bb10b925e5e7/pkg/runtime).
   In particular, you need an executable with a command like `config <name>` to return the resolved value
   just like your service would see it for `db.url`, `db.name`, `db.username`, `db.schema`, `migration.dir`.

2. In your project Makefile, add:

        READ_CONFIG_CMD := ./bin/<my-executable>
        include ./mk-include/cc-db.mk
3. You can check the configuration used by this plugin using

        % make show-db
        DB_SCHEMA_FILE: ./db/schema.sql
        DB_SEED_FILE: ./db/seeds.sql
        READ_CONFIG_CMD: ./bin/go-template-service
        DATABASE_URL: postgres://go_template_service@127.0.0.1:5432/go_template_service?sslmode=disable
        DATABASE_NAME: go_template_service
        DATABASE_USER: go_template_service
        DATABASE_SCHEMA: go_template_service
        MIGRATION_DIR: db/migrations
        MIGRATION_DIR_URL: file://db/migrations
        MIGRATION_DB_URL: postgres://go_template_service@127.0.0.1:5432/go_template_service?sslmode=disable&search_path=go_template_service&x-migrations-table-quoted=true&x-migrations-table="go_template_service"."schema_migrations"
        ADMIN_DB_URL: postgres://

4. Now you have access to some great `db` and `db-migrate` make targets:

        % make help | grep -E '\x1b\[36mdb-'
        db-dump-schema      Dump the current DB schema and migration version to $(DB_SCHEMA_FILE)
        db-local-reset      Reset the local database from the schema, migrations, and seeds
        db-migrate-create   Create a new DB migration. Usage: make db-migrate-create NAME=migration_name_here
        db-migrate-down     Rollback DB migrations. Usage: make db-migrate-down [N=1, default 1]
        db-migrate-force    Force override the DB migration version in the DB to a specific version
        db-migrate-goto     Go to a specific DB migration version
        db-migrate-up       Apply DB migrations. Usage: make db-migrate-up [N=1, default all]
        db-migrate-version  Show current DB migration version
        db-seed             Seed the database from $(DB_SEED_FILE)
        db-seed-dump        Overwrite the $(DB_SEED_FILE) from the current database

5. Not strictly a requirement, but these make targets are designed primarily for local development.
   While it's possible to build a release strategy using this, the designed approach is to use
   `dbmigrate.Module`'s built-in auto-migrator support in the new runtime library. Then the only
   time any of this is used in production is for emergency rollback cases, in which you have to
   `exec` in to a service pod and call one of these targets.

## Developing

If you're developing an app that uses cc-mk-include or needs to extend it, it's useful
to understand how the "library" is structured.

The consistent developer experience of `make build`, `make test`, etc. is enabled by exposing a
handful of extension points that are used internally and available for individual apps as well.
For example, when you include `cc-go.mk` it adds `clean-go` to `CLEAN_TARGETS`, `build-go` to
`BUILD_TARGETS`, and so on. Each of these imports (like `semver`, `go`, `docker`, etc) is
essentially a standardized extension.

**The ultimate effect is to be able to "mix and match" different extensions
(e.g., semver, docker, go, helm, cpd) for different applications.**

You can run `make show-args` when you're inside any given project to see what extensions
are enabled for a given standard extensible command. For example, we can see that when you
run `make build` in the `cc-scheduler-service`, it'll run `build-go`, `build-docker`, and
`helm-package`.
```
cc-scheduler-service cody$ make show-args
INIT_CI_TARGETS:      seed-local-mothership deps cpd-update gcloud-install helm-setup-ci
CLEAN_TARGETS:         clean-go clean-images clean-terraform clean-cc-system-tests helm-clean
BUILD_TARGETS:         build-go build-docker helm-package
TEST_TARGETS:          lint-go test-go test-cc-system helm-lint
RELEASE_TARGETS:      set-tf-bumped-version helm-set-bumped-version get-release-image commit-release tag-release cc-cluster-spec-service push-docker
RELEASE_MAKE_TARGETS:  bump-downstream-tf-consumers helm-release
CI_BIN:
```

This also shows the full list of supported extension points (`INIT_CI_TARGETS`, `CLEAN_TARGETS`, and so on).

Applications themselves may also use these extension points; for example, you can append
your custom `clean-myapp` target to `CLEAN_TARGETS` to invoke as part of `make clean`.

```
SERVICE_NAME := myapp
CLEAN_TARGETS += clean-myapp

include ./mk-include/cc-begin.mk
include ./mk-include/cc-api.mk
include ./mk-include/cc-semver.mk
include ./mk-include/cc-end.mk

.PHONY: clean-myapp
clean-myapp:
  rm some/special/file
```
Running `make show-args` will now show your new task
```
$ make show-args | grep CLEAN
CLEAN_TARGETS:        clean-myapp  api-clean
```

If you need to _append_ your target to this list to run after the others, you can do that by
adding it after the mk-include imports, for example
```
SERVICE_NAME := myapp

include ./mk-include/cc-begin.mk
include ./mk-include/cc-semver.mk
include ./mk-include/cc-api.mk
include ./mk-include/cc-end.mk

CLEAN_TARGETS += clean-myapp

.PHONY: clean-myapp
clean-myapp:
  rm some/special/file
```

Running `make show-args` will show the order these will actually be invoked:
```
$ make show-args | grep CLEAN
CLEAN_TARGETS:        api-clean clean-myapp
```

We also expose a small number of override points for special cases (e.g., `BUILD_DOCKER_OVERRIDE`)
but these should be rather rare.

### IntelliJ / Goland Debugging

*Note*: for now, only supported on OS X Intel

The `test-go-goland-debug` target is provided to enable remote debugging of Go
applications via the IntelliJ/Goland integrated debugger (via delve).  If
using a typical Goland installation, then no special overriding should be
needed.  However, there are two environment variables that will affect the
remote debugger.

* `GOLAND_PORT` - the port to start the delve server on (defaults to 12345)
* `GOLAND_PLUGIN_PATH` - the path to the IntelliJ Go plugin (which is
                         assumed to contain the dlv executable at a certain
                         subpath - `./lib/dlv/mac/dlv`)

For a normal Goland installation, neither of these need to be changed.
For IntelliJ Ultimate with the Go plugin, then `GOLAND_PLUGIN_PATH` will
need to be set to something
`~/Library/Application\ Support/JetBrains/IntelliJIdea2021.3/plugins/go`

See [go/goland](https://go/goland) for more information.
