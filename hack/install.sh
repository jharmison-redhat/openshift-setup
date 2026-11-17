#!/usr/bin/env bash

cd "$(dirname "$(realpath "$0")")/.." || exit 1
source hack/common.sh

if cluster_validate || metadata_validate; then
    echo "Skipping install" >&2
    touch "${INSTALL_DIR}/auth/kubeconfig"
    exit 0
fi

if ! pull_secret_validate_and_clean; then
    echo "Copy your pull secret from: https://console.redhat.com/openshift/install/pull-secret"
    PULL_SECRET="$(read_secret Paste your pull secret here)"
    if ! pull_secret_validate_and_clean; then
        echo "Invalid or empty pull secret provided" >&2
        exit 1
    fi
    cat <<EOF >>".env"
export PULL_SECRET='${PULL_SECRET}'
EOF
fi

if ! aws_validate; then
    AWS_ACCESS_KEY_ID="$(read_secret Enter your AWS_ACCESS_KEY_ID for "${CLUSTER_URL}")"
    AWS_SECRET_ACCESS_KEY="$(read_secret Enter your AWS_SECRET_ACCESS_KEY for "${CLUSTER_URL}")"
    export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
    if ! aws_validate; then
        echo "Invalid or empty AWS credentials provided" >&2
        exit 1
    fi
    cat <<EOF >>"${INSTALL_DIR}.env"
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
    \$WORKER_DISK_SIZE
    \$CONTROL_PLANE_TYPE
    \$CONTROL_PLANE_COUNT
)
vars=$(concat_with_comma "${templated_variables[@]}")
envsubst "$vars" <install-config.yaml.tpl >"${INSTALL_DIR}/install-config.yaml"
if [ -n "${OS_IMAGE_STREAM:-}" ]; then
  echo "osImageStream: ${OS_IMAGE_STREAM}" >>"${INSTALL_DIR}/install-config.yaml"
fi

echo "install-config.yaml:"
sed 's/^/  /' "${INSTALL_DIR}/install-config.yaml"

set -x
"${INSTALL_DIR}/openshift-install" --dir "${INSTALL_DIR}" create cluster
