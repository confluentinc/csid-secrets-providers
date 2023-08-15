#!/bin/bash

BUILD_DIR="${BUILD_DIR:-$SEMAPHORE_GIT_DIR/build}"
RERUN_DIR="${RERUN_DIR:-$BUILD_DIR/rerun-data}"

# must match with RERUN_DATA_KEY in store_rerun_data
FIX_JOB_NAME=$(echo $SEMAPHORE_JOB_NAME | tr -d ',' | tr ' ' '-')
RERUN_DATA_KEY="${SEMAPHORE_WORKFLOW_ID}-${FIX_JOB_NAME}-rerun-data"


if [[ "$SEMAPHORE_PIPELINE_PROMOTION" == "false" ]]; then
# seems to be the case that sometimes semaphore workflow ids arn't unique, to fix this delete if on first run theres a hit
    cache delete "$RERUN_DATA_KEY" || true
fi
cache restore "$RERUN_DATA_KEY"
if [ -f "${RERUN_DIR}/failed_test.txt" ]; then
    export RERUN_TESTS="$(cat ${BUILD_DIR}/rerun-data/failed_test.txt)"
    if [ -n "$RERUN_TESTS" ]; then 
        echo "rerunning: $RERUN_TESTS"
    else
        echo "no tests to rerun found, using originally configured value"
    fi
else
    echo "file '${RERUN_DIR}/failed_test.txt' not found"
fi

# reset status of rerun_dir to be cleared out to be written to durring test execution
rm -rf "${RERUN_DIR}"
mkdir -p "${RERUN_DIR}"
