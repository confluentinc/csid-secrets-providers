#!/usr/bin/env bash

set -e

SPECTRAL_OUTPUT=$(cat)

echo "$SPECTRAL_OUTPUT"

if [[ -z "${CI}" || "$CI" = false ]]; then
  exit 0
fi

NAME="${1}"
HEADER="**OpenAPI Linter Output for $NAME**"
COMMENT_CONTENT="$SPECTRAL_OUTPUT"
COMMENT="${HEADER}<br /><br /><pre>${COMMENT_CONTENT}</pre>"
COMMENT=$(echo "$COMMENT" | awk 1 ORS='<br />')

if [[ ! -z $COMMENT_CONTENT && ! -z $SEMAPHORE_GIT_PR_NUMBER ]]; then
  if git diff --name-only `git merge-base master HEAD` | grep -v ccloud/openapi.yaml | grep ${NAME}; then
    if [[ $SPECTRAL_OUTPUT != *"No linter violations"* ]]; then
      echo -n $COMMENT >> ~/openapi-linter-warnings.txt
    fi
  fi
fi
