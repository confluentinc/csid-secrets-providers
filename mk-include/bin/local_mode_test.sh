#!/usr/bin/env bash

BINARY=${1}

# Fail CI if this test fails by setting to true
LOCAL_MODE_TEST_FAIL_CI=${LOCAL_MODE_TEST_FAIL_CI:-false}

# Port to start the service on. (We ignore/override ports from config.yaml)
DEBUG_PORT=${DEBUG_PORT:-6060}

# "Advanced" configuration options
LOCAL_MODE_TEST_LOG_FILE=${LOCAL_MODE_TEST_LOG_FILE:-local_mode_test.log}
LOCAL_MODE_TEST_HEALTH_CHECK_FILE=${LOCAL_MODE_TEST_HEALTH_CHECK_FILE:-local_mode_test.hc}
DEBUG=${DEBUG:-}

trap cleanup EXIT

function cleanup {
  rv="$?"

  # keep the logs for debugging if errors
  if [ "${rv}" -eq 0 ]; then
    rm -f "${LOCAL_MODE_TEST_LOG_FILE}" "${LOCAL_MODE_TEST_HEALTH_CHECK_FILE}"
  fi

  # make sure the process is stopped
  if [ -f "./${BINARY}.pid" ]; then
    pid=$(cat "./${BINARY}.pid")
    kill -s TERM "${pid}" >/dev/null 2>&1 || true
    rm "./${BINARY}.pid"
  fi

  if [ "${rv}" -eq 1 ] && [ "${LOCAL_MODE_TEST_FAIL_CI}" == "true" ]; then
    exit 1
  fi
  exit 0
}

function validate_no_error_logs {
  name=$1

  if grep "ERROR" "${LOCAL_MODE_TEST_LOG_FILE}" | grep -v "healthcheck has failed"; then
    echo "ERROR on ${name} - check ${LOCAL_MODE_TEST_LOG_FILE}"
    exit 1
  fi
}

function validate_process_alive {
  if ! pgrep -F "./${BINARY}.pid" > /dev/null; then
    echo "Process failed to start - check ${LOCAL_MODE_TEST_LOG_FILE}"
    exit 1
  fi
}

function check_health {
  name=$1
  enable_if_log_line=$2
  check=$3
  results=$4

  attempt_num=1
  sleepy_time=5
  max_attempts=12 # a whole minute

  if grep -q "${enable_if_log_line}" "${LOCAL_MODE_TEST_LOG_FILE}"; then
    while [ $attempt_num -le $max_attempts ]; do
      # this has pipes so have to eval - safe because ${check} and ${results} aren't user supplied, internal to this script
      if eval "${check}"; then
        echo "${name} attempt ${attempt_num} - OK"
        return
      else
        echo "${name} attempt ${attempt_num} - Failed"
        attempt_num=$(( attempt_num + 1 ))
        sleep ${sleepy_time}
      fi
    done
    echo "Results:"
    eval "${results}"
    exit 1
  fi
}

function run_local_mode_test {
  if [ -n "${DEBUG}" ]; then
    set -x # echo on
  fi

  if [ -z "${BINARY}" ]; then
    echo "missing required first argument: path/to/binary"
    exit 1
  fi
  if [ ! -f "./${BINARY}" ]; then
    echo "invalid binary: ./${BINARY} doesn't exist"
    exit 1
  fi
  if [ ! -x "./${BINARY}" ]; then
    echo "invalid binary: ./${BINARY} is not executable"
    exit 1
  fi

  # start the service with healthcheck ports (assumes service-runtime-go command-line flags)
  "./${BINARY}" --debug.addr ":${DEBUG_PORT}" > "${LOCAL_MODE_TEST_LOG_FILE}" 2>&1 &
  pid="$!"
  echo "${pid}" > "./${BINARY}.pid"
  echo "Starting on PID ${pid}"

  if [ -n "${DEBUG}" ]; then
    ps aux | grep "${BINARY}"
  fi

  # wait for running (assumes Fx logs)
  echo "Waiting for RUNNING"
  while ! grep -q "RUNNING" "${LOCAL_MODE_TEST_LOG_FILE}"; do
    validate_process_alive
    sleep 1
  done

  validate_no_error_logs "startup"

  check_health "Healthcheck" "Starting the debug server" \
    "curl -s -S localhost:${DEBUG_PORT}/chc | tee ${LOCAL_MODE_TEST_HEALTH_CHECK_FILE} | grep -q -v '\"failed\"'" \
    "cat ${LOCAL_MODE_TEST_HEALTH_CHECK_FILE} | jq ."

  kill -s TERM ${pid}

  validate_no_error_logs "shutdown"
}

run_local_mode_test
