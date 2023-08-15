#!/bin/bash
set -e
# set creds for github cli
${MAKE} github-cli-auth

# preserve current branch
if [[ $(${GIT} branch --show-current) ]]; then
    GIT_PRESERVED_BRANCH=$(${GIT} branch --show-current)
else
    GIT_PRESERVED_BRANCH=$(${GIT} rev-parse HEAD)
    ${GIT} checkout -b "${GIT_PRESERVED_BRANCH}"
fi

# check if PR already existed
if gh pr list -B "${MASTER_BRANCH}" | grep "${MK_INCLUDE_UPDATE_COMMIT_MESSAGE}"; then
    # fetch update branch
    ${GIT} fetch "${GIT_REMOTE_NAME}" "${MK_INCLUDE_UPDATE_BRANCH}":"${MK_INCLUDE_UPDATE_BRANCH}"
    ${GIT} checkout "${MK_INCLUDE_UPDATE_BRANCH}"
else
    # fetch current master branch
    ${GIT} fetch "${GIT_REMOTE_NAME}" "${MASTER_BRANCH}"
    ${GIT} branch -D "${MK_INCLUDE_UPDATE_BRANCH}" &>/dev/null || true
    ${GIT} checkout -b "${MK_INCLUDE_UPDATE_BRANCH}" FETCH_HEAD
fi

# compare git hash
if grep -q -e "${MK_INCLUDE_GIT_HASH}" "${MK_INCLUDE_GIT_HASH_LOCATION}" ; then
    echo "mk-include is already at newest pinned version"
else
    ${MAKE} update-mk-include
    ${GIT} push -f "${GIT_REMOTE_NAME}" "${MK_INCLUDE_UPDATE_BRANCH}"
    echo "update cc-mk-include finished, open update PR"
    gh pr create -B "${MASTER_BRANCH}" -b "update mk-include" -t "${MK_INCLUDE_UPDATE_COMMIT_MESSAGE}" -H "${MK_INCLUDE_UPDATE_BRANCH}" || true
fi

# switch back to previous preserved branch
${GIT} checkout "${GIT_PRESERVED_BRANCH}"
