#!/bin/bash

cd "$(dirname "$(realpath "$0")")/.." || exit 1
source hack/common.sh

rm -rf "${CLUSTER_DIR}"

aws_validate
metadata_validate

if aws_validate_functional; then
	set -x
	"${INSTALL_DIR}/openshift-install" --dir "${INSTALL_DIR}" destroy cluster
else
	set -x
fi

rm -rf "${INSTALL_DIR}"
rm -rf "${CLUSTER_DIR}"
