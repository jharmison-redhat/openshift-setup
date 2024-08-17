#!/bin/bash

cd "$(dirname "$(realpath "$0")")/.." || exit 1
source hack/common.sh

if metadata_validate && ! ${RECOVER_INSTALL}; then
	echo "Skipping install" >&2
	touch "${INSTALL_DIR}/auth/kubeconfig"
	exit 0
fi

if ! pull_secret_validate; then
	echo "Copy your pull secret from: https://console.redhat.com/openshift/install/pull-secret"
	echo -n "Paste it here: "
	unset PULL_SECRET
	while IFS= read -r -s -n1 pass; do
		if [[ -z $pass ]]; then
			echo
			break
		else
			echo -n '*'
			PULL_SECRET+="$pass"
		fi
	done
	echo
	cat <<EOF >>".env"
export PULL_SECRET='${PULL_SECRET}'
EOF
fi

if ! aws_validate; then
	read -rsp "Enter your AWS_ACCESS_KEY_ID for ${CLUSTER_URL}: " AWS_ACCESS_KEY_ID
	echo
	read -rsp "Enter your AWS_SECRET_ACCESS_KEY for ${CLUSTER_URL}: " AWS_SECRET_ACCESS_KEY
	echo
	export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
	aws_validate
	cat <<EOF >>"${INSTALL_DIR}/.env"
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
EOF
fi

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

if ${RECOVER_INSTALL}; then
	"${INSTALL_DIR}/openshift-install" --dir "${INSTALL_DIR}" wait-for bootstrap-complete || :
	"${INSTALL_DIR}/openshift-install" --dir "${INSTALL_DIR}" destroy bootstrap || :
	"${INSTALL_DIR}/openshift-install" --dir "${INSTALL_DIR}" wait-for install-complete
	touch "${INSTALL_DIR}/auth/kubeconfig"
else
	"${INSTALL_DIR}/openshift-install" --dir "${INSTALL_DIR}" create cluster
fi
