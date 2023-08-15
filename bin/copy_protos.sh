#!/usr/bin/env bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Folder that will contain all the .proto files for component tests
PROTO_DIR="${DIR}/../../test/proto"

start_cleanup() {
  rm -rf "${PROTO_DIR}"
}

exit_cleanup() {
  rm -rf "${GIT_DIR}"
}

trap exit_cleanup EXIT
start_cleanup

mkdir -p "${PROTO_DIR}"

GIT_DIR="$(mktemp -d)"
CC_STRUCTS_GIT_DIR="${GIT_DIR}/cc-structs"
cd "${GIT_DIR}"
git clone git@github.com:confluentinc/cc-structs.git
cd "${CC_STRUCTS_GIT_DIR}"

make deps


protodirs=(events metrics kafka operator customresource roll scheduler_plugins)
for d in "${protodirs[@]}"
do
  PROTOS=$(find "${d}" -type f -name "*.proto")
  for p in ${PROTOS}; do
    echo "${p}"
    rsync -R "${p}" "${PROTO_DIR}"
  done
done

cd "vendor"
protodirs=(github.com/gogo/protobuf/gogoproto github.com/gogo/protobuf/protobuf k8s.io)
for d in "${protodirs[@]}"
do
  PROTOS=$(find "${d}" -type f -name "*.proto")
  for p in ${PROTOS}; do
    echo "${p}"
    rsync -R "${p}" "${PROTO_DIR}"
  done
done

cp -R "${PROTO_DIR}/github.com/gogo/protobuf/protobuf/google" "${PROTO_DIR}"
cp -R "${PROTO_DIR}/github.com/gogo/protobuf/gogoproto" "${PROTO_DIR}"
rm -rf "${PROTO_DIR}/github.com/"

cp "$(go list -f '{{ .Dir }}' -m github.com/confluentinc/proto-go-setter)"/setter.proto  "${PROTO_DIR}/setter.proto"
cp "$(go list -f '{{ .Dir }}' -m github.com/travisjeffery/proto-go-sql)"/sql.proto  "${PROTO_DIR}/sql.proto"
mkdir "${PROTO_DIR}/validate"
go get github.com/envoyproxy/protoc-gen-validate
cp "$(go list -f '{{ .Dir }}' -m github.com/envoyproxy/protoc-gen-validate)"/validate/validate.proto "${PROTO_DIR}/validate/validate.proto"
