#!/usr/bin/env bash

cd "$(dirname "$(realpath "$0")")/.." || exit 1
source hack/common.sh

rm -rf "${CLUSTER_DIR}"

aws_validate
metadata_validate

if aws_validate_functional; then
	set -x
	"${INSTALL_DIR}/openshift-install" --dir "${INSTALL_DIR}" destroy cluster
else
	{
		echo "ERROR: AWS credentials are set but non-functional (STS call failed)."
		echo "Refusing to remove ${INSTALL_DIR}: the AWS resources could not be verified and would be orphaned."
		echo "Fix the credentials and re-run, or run: ${INSTALL_DIR}/openshift-install --dir ${INSTALL_DIR} destroy cluster"
	} >&2
	exit 1
fi

rm -rf "${INSTALL_DIR}"
rm -rf "${CLUSTER_DIR}"
