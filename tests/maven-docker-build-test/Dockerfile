#
# Copyright 2018 Confluent Inc.
#
ARG DOCKER_UPSTREAM_TAG

# https://github.com/confluentinc/cc-docker-base
FROM 519856050701.dkr.ecr.us-west-2.amazonaws.com/docker/prod/confluentinc/cc-base:v18.6.0

ARG PROJECT_VERSION
ARG ARTIFACT_ID

LABEL io.confluent.caas=true
ARG COMMIT_ID=unknown
LABEL io.confluent.docker.git.id=$COMMIT_ID
ARG BUILD_NUMBER=-1
LABEL io.confluent.docker.build.number=$BUILD_NUMBER

###

ADD target/${ARTIFACT_ID}* /usr/share/java/${ARTIFACT_ID}/

RUN apt-get update \
    && apt-get install jq -y
