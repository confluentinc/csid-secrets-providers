#!/bin/bash

# must match with RERUN_DATA_KEY in load_rerun_data
FIX_JOB_NAME=$(echo $SEMAPHORE_JOB_NAME | tr -d ',' | tr ' ' '-')
RERUN_DATA_KEY="${SEMAPHORE_WORKFLOW_ID}-${FIX_JOB_NAME}-rerun-data"

BUILD_DIR="${BUILD_DIR:-$SEMAPHORE_GIT_DIR/build}"

[ "$DEBUG" = true ] && set -x
set -e

# delete old cache key if exists
cache delete "$RERUN_DATA_KEY"

if [ -d "${BUILD_DIR}/rerun-data" ]; then
    echo "storing data in $RERUN_DATA_KEY"
    cache store "$RERUN_DATA_KEY" "${BUILD_DIR}/rerun-data"
    if [ -f "${BUILD_DIR}/rerun-data/failed_test.txt" ]; then
        echo "found failed tests:"
        cat "${BUILD_DIR}/rerun-data/failed_test.txt"
        echo ""
        artifact push job "${BUILD_DIR}/rerun-data/failed_test.txt" -d "rerun-data/${SEMAPHORE_JOB_NAME}/failed_test.txt"
    else
        echo "failed tests not found"
    fi
else
    echo "rerun data not found: ${BUILD_DIR}/rerun-data"
fi
