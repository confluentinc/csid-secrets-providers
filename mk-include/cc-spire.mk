MK_INCLUDE_SPIRE := $(GIT_ROOT)/mk-include/spire

INIT_CI_TARGETS += start-spire

DOCKER_COMPOSE := docker-compose -f ${MK_INCLUDE_SPIRE}/docker-compose.yml

# Need this to be able to pull from nonprod GAR, see https://stackoverflow.com/a/70555005
ifeq ($(CI),true)
export LD_LIBRARY_PATH := /usr/local/lib/
endif

.PHONY: start-spire
start-spire: start-spire-server start-spire-agent

.PHONY: start-spire-server
start-spire-server:
	${DOCKER_COMPOSE} -f $(MK_INCLUDE_SPIRE)/docker-compose.yml up -d spire-server

.PHONY: register-spire-entries
register-spire-entries:
	# Use 0 because in the docker container this command runs as root, and anything talking to the agent will be seen
	# as the root because the agent runs in a docker container too
	${DOCKER_COMPOSE} exec spire-server /opt/spire/bin/spire-server entry create -selector unix:gid:0 \
		-spiffeID spiffe://example.org/test-workload -parentID spiffe://example.org/test-agent

.PHONY: start-spire-agent
start-spire-agent:
	## Check status and break loop if successful
	@for i in 1 2 3; do \
		${DOCKER_COMPOSE} exec spire-server /opt/spire/bin/spire-server entry show > /dev/null; \
		if [ "$$?" -eq 0 ]; \
		then  \
			echo "Spire server is UP, continuing..."; \
			break; \
		fi; \
		if [ "$$i" -eq 3 ]; \
		then  \
			echo "Spire server is not running, exiting..."; \
			exit 1; \
		fi; \
		sleep 3; \
	done

	$(eval token := $(shell ${DOCKER_COMPOSE} exec spire-server /opt/spire/bin/spire-server token generate -spiffeID spiffe://example.org/test-agent | awk '{print $$NF}'))
	JOIN_TOKEN=$(token) ${DOCKER_COMPOSE} up -d spire-agent

	make --ignore-errors register-spire-entries

.PHONY: stop-spire
stop-spire:
	${DOCKER_COMPOSE} down
