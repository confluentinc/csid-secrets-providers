# We use https://github.com/golang-migrate/migrate
MIGRATE ?= migrate

# TODO: Avoid pg_dump version mismatch where multiple postgres versions are installed by specifying the absolute path.
PG_DUMP ?= pg_dump
DB_SCHEMA_FILE ?= ./db/schema.sql
DB_SEED_FILE ?= ./db/seeds.sql
ADMIN_DB_URL ?= postgres://

# Only need to reset db before CI runs tests
ifeq ($(CI),true)
PRE_TEST_TARGETS += install-migrate db-local-reset
endif

.PHONY: install-migrate
install-migrate:
	# This tag makes it install only the postgres DB driver to avoid extra dependency bloat
	go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@84009cf2ab468c0d7610385c23484dbbba9b5237

.PHONY: show-db-migrate
## Show DB migrate variables
show-db: _db-vars
	@echo "DB_SCHEMA_FILE: $(DB_SCHEMA_FILE)"
	@echo "DB_SEED_FILE: $(DB_SEED_FILE)"
	@echo "READ_CONFIG_CMD: $(READ_CONFIG_CMD)"
	@echo "DATABASE_URL: $(DATABASE_URL)"
	@echo "DATABASE_NAME: $(DATABASE_NAME)"
	@echo "DATABASE_USER: $(DATABASE_USER)"
	@echo "DATABASE_SCHEMA: $(DATABASE_SCHEMA)"
	@echo "MIGRATION_DIR: $(MIGRATION_DIR)"
	@echo "MIGRATION_DIR_URL: $(MIGRATION_DIR_URL)"
	@echo "MIGRATION_DB_URL: $(MIGRATION_DB_URL)"
	@echo "ADMIN_DB_URL: $(ADMIN_DB_URL)"

.PHONY: psql
psql: _db-vars
	psql -P pager=off "$(DATABASE_URL)"

.PHONY: db-migrate-create
## Create a new DB migration. Usage: make db-migrate-create NAME=migration_name_here
db-migrate-create: _db-vars
ifndef NAME
	$(error NAME is not set. Usage: make db-migrate-create NAME=migration_name_here)
endif
	$(eval MIGRATION_FILES=$(shell $(MIGRATE) create -dir $(MIGRATION_DIR) -ext sql $(NAME) 2>&1 | sed -e 's/.*\/\(.*\)/\1/g'))
	@for file in $(MIGRATION_FILES); do echo -e "BEGIN;\n\n-- do work here\n\nCOMMIT;" > $(MIGRATION_DIR)/$${file}; done

.PHONY: db-migrate-up
## Apply DB migrations. Usage: make db-migrate-up [N=1, default all]
db-migrate-up:
	@$(MAKE) _db-migrate-with-dump COMMAND="up $(N)"

.PHONY: db-migrate-down
## Rollback DB migrations. Usage: make db-migrate-down [N=1, default 1]
db-migrate-down:
ifndef N
	$(eval N=1)
endif
	@$(MAKE) _db-migrate-with-dump COMMAND="down $(N)"

.PHONY: db-migrate-goto
## Go to a specific DB migration version
db-migrate-goto:
ifndef VER
	$(error VER is not set. Usage: make db-migrate-goto VER=20220127214354)
endif
	@$(MAKE) _db-migrate-with-dump COMMAND="goto $(VER)"

.PHONY: db-migrate-version
## Show current DB migration version
db-migrate-version:
	@$(MAKE) _db-migrate-with-nodump COMMAND="version"

.PHONY: db-migrate-force
## Force override the DB migration version in the DB to a specific version
db-migrate-force:
ifndef VER
	$(error VER is not set. Usage: make db-migrate-force VER=20220127214354)
endif
	@$(MAKE) _db-migrate-with-dump COMMAND="force $(VER)"

.PHONY: db-dump-schema
## Dump the current DB schema and migration version to $(DB_SCHEMA_FILE)
db-dump-schema: _db-vars
	$(PG_DUMP) "$(DATABASE_URL)" --schema-only --schema=$(DATABASE_SCHEMA) > $(DB_SCHEMA_FILE) && \
		$(PG_DUMP) "$(DATABASE_URL)" --data-only --table=$(DATABASE_SCHEMA).schema_migrations >> $(DB_SCHEMA_FILE) && \
		echo "Schema dumped to $(DB_SCHEMA_FILE)";

.PHONY: db-seed
## Seed the database from $(DB_SEED_FILE)
db-seed: _db-vars
	@PGOPTIONS=--search_path=$(DATABASE_SCHEMA) psql -P pager=off --set ON_ERROR_STOP=on "${ADMIN_DB_URL}/$(DATABASE_NAME)" < "$(DB_SEED_FILE)";

.PHONY: db-seed-dump
## Overwrite the $(DB_SEED_FILE) from the current database
db-seed-dump: _db-vars
	@$(PG_DUMP) "$(DATABASE_URL)" --data-only --schema=$(DATABASE_SCHEMA) --exclude-table-data=$(DATABASE_SCHEMA).schema_migrations > $(DB_SEED_FILE)

.PHONY: db-local-reset
## Reset the local database from the schema, migrations, and seeds
db-local-reset: _db-vars
ifdef CC_DOTFILES_DB_TUNNEL
	@echo "Unsafe operation, unsupported over SSH tunnel, abort. (CC_DOTFILES_DB_TUNNEL is set)."
	@exit 1
endif
	psql -P pager=off "${ADMIN_DB_URL}/postgres" -c 'DROP DATABASE IF EXISTS $(DATABASE_NAME)'
	psql -P pager=off "${ADMIN_DB_URL}/postgres" -c 'CREATE DATABASE $(DATABASE_NAME)'
	psql -P pager=off "${ADMIN_DB_URL}/postgres" -c 'DROP ROLE IF EXISTS $(DATABASE_USER)'
	psql -P pager=off "${ADMIN_DB_URL}/postgres" -c 'CREATE ROLE $(DATABASE_USER) WITH LOGIN'
	if [ -f "$(DB_SCHEMA_FILE)" ]; then psql -P pager=off --set ON_ERROR_STOP=on "${ADMIN_DB_URL}/$(DATABASE_NAME)" < "$(DB_SCHEMA_FILE)"; \
	else psql -P pager=off "${ADMIN_DB_URL}/$(DATABASE_NAME)" -c 'CREATE SCHEMA $(DATABASE_SCHEMA)'; \
		psql -P pager=off "${ADMIN_DB_URL}/$(DATABASE_NAME)" -c 'ALTER SCHEMA $(DATABASE_SCHEMA) OWNER TO $(DATABASE_USER)'; fi
	$(MAKE) db-migrate-up db-seed

.PHONY: _db-migrate-with-dump
_db-migrate-with-dump: _db-vars
ifndef COMMAND
	$(error COMMAND is not set. Usage: _db-migrate-with-dump COMMAND="up $$(N)")
endif
	@if [ -z "$(MIGRATION_DIR)" ]; then  \
        	echo "Skipping db migrate $(COMMAND) because MIGRATION_DIR is empty"; \
    		exit 0; \
    	else \
 		OUTPUT=$$($(MIGRATE) -source "$(MIGRATION_DIR_URL)" -database "$(MIGRATION_DB_URL)" $(COMMAND) 2>&1); \
		if [ $$? -eq 1 ]; then echo "$${OUTPUT}"; exit 1; else echo "$${OUTPUT}"; fi; \
		echo "$${OUTPUT}" | grep -q -v "no change"; \
		if [ $$? -eq 0 ]; then $(MAKE) db-dump-schema; else exit 0; fi; \
    	fi; \

.PHONY: _db-migrate-with-nodump
_db-migrate-with-nodump: _db-vars
ifndef COMMAND
	$(error COMMAND is not set. Usage: _db-migrate-with-nodump COMMAND="force $$(VER)")
endif
	@if [ -z "$(MIGRATION_DIR)" ]; then  \
        	echo "$(MIGRATION_DIR)"; \
        	echo "Skipping db migrate $(COMMAND) because MIGRATION_DIR is empty"; \
    		exit 0; \
  	else \
		$(MIGRATE) -source "$(MIGRATION_DIR_URL)" -database "$(MIGRATION_DB_URL)" $(COMMAND) 2>&1; \
	fi; \

# User should add a make target in their Makefile with name $(READ_CONFIG_CMD) to build the executable which will output the db config
.PHONY: _db-vars
_db-vars: $(READ_CONFIG_CMD)
# READ_CONFIG_CMD should point to a server executable with a "config <name>" command to return the resolved
# config value for <name>. The normal approach here is to setup your service to use service-runtime-for-go
# (currently at https://github.com/confluentinc/cc-go-template-service/pkg/runtime).
ifndef READ_CONFIG_CMD
	@echo 'READ_CONFIG_CMD must be set to an executable exposing a "config <name>" command to return resolved configurations'
	@exit 1
endif
	$(eval READ_CONFIG=$(READ_CONFIG_CMD) config)
	$(eval DATABASE_URL=$(shell $(READ_CONFIG) db.url))
	$(eval DATABASE_NAME=$(shell $(READ_CONFIG) db.name))
	$(eval DATABASE_USER=$(shell $(READ_CONFIG) db.username))
	$(eval DATABASE_SCHEMA=$(shell $(READ_CONFIG) db.schema))
	$(eval MIGRATION_DIR=$(shell $(READ_CONFIG) migration.dir))
	$(eval MIGRATION_DIR_URL=file://$(MIGRATION_DIR))
	$(eval MIGRATION_DB_URL=$(DATABASE_URL)&search_path=$(DATABASE_SCHEMA)&x-migrations-table-quoted=true&x-migrations-table=\"$(DATABASE_SCHEMA)\".\"schema_migrations\")
