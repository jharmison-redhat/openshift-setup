#!/bin/bash

cd "$(dirname "$(realpath "$0")")/.." || exit 1
source hack/common.sh

if metadata_validate; then
	echo "Skipping install" >&2
	exit 0
fi

pull_secret_validate
aws_validate

hack/hosted-zone.sh

SSH_KEY="$(cat "${INSTALL_DIR}/id_ed25519.pub")"
export SSH_KEY

templated_variables=(
	\$PULL_SECRET
	\$AWS_REGION
	\$AWS_ACCESS_KEY_ID
	\$AWS_SECRET_ACCESS_KEY
	\$CLUSTER_NAME
	\$BASE_DOMAIN
	\$SSH_KEY
	\$WORKER_TYPE
	\$WORKER_COUNT
	\$CONTROL_PLANE_TYPE
	\$CONTROL_PLANE_COUNT
)
vars=$(concat_with_comma "${templated_variables[@]}")

envsubst "$vars" <install-config.yaml.tpl >"${INSTALL_DIR}/install-config.yaml"

echo "install-config.yaml:"
sed 's/^/  /' "${INSTALL_DIR}/install-config.yaml"

set -x

"${INSTALL_DIR}/openshift-install" --dir "${INSTALL_DIR}" create cluster
