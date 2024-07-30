#!/bin/bash

cd "$(dirname "$(realpath "$0")")/.." || exit 1
source hack/common.sh

rm -rf "${CLUSTER_DIR}"

aws_validate
metadata_validate

set -x

"${INSTALL_DIR}/openshift-install" --dir "${INSTALL_DIR}" destroy cluster
