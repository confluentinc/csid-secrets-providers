#!/bin/bash
# comment on PRs(if exists) with golangci-lint results
# This scripts should be only run in CI
# The scripts is used in early adoption, 
# and will be remove if golangci-lint is adopted as default lint

set -e
output_file=${1:-./golangci-lint.output}
# remove make noise
sed -i.bak '/Job is running on Semaphore*/d' "${output_file}"
sed -i.bak '/make\[1\]:/d' "${output_file}"

if grep "golangci-lint found no issues" "${output_file}" ; then
    echo "golangci-lint found no issues, no comments will be made"
    rm "${output_file}"
    exit 0
fi;

if [ ! -s "${output_file}" ]; then
    echo "golangci-lint found no issues, no comments will be made"
    rm "${output_file}"
    exit 0
fi;

if [ -z "$SEMAPHORE_GIT_PR_NUMBER" ]; then
    if gh pr status | grep 'There is no pull request associated with'; then
        echo "no PR found for this branch, abort commenting on PRs"
        rm "${output_file}"
        exit 0
    fi;
fi

sed -i '1s/^/```\n/' "${output_file}"
sed -i '1s/^/**golangci-lint output**:\n/' "${output_file}"
echo "\`\`\`" >> "${output_file}"

if [ -z "$SEMAPHORE_GIT_PR_NUMBER" ]; then
    gh pr comment -F "${output_file}"
else
    gh pr comment $SEMAPHORE_GIT_PR_NUMBER -F "${output_file}"
fi

rm "${output_file}"
