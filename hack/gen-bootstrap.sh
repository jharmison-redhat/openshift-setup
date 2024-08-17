#!/bin/bash

cd "$(dirname "$(realpath "$0")")/.." || exit 1
source hack/common.sh

bootstrap_dir="${INSTALL_DIR}/bootstrap"
mkdir -p "$bootstrap_dir"

ARGO_SSH_SECRET="$(cat "${INSTALL_DIR}/argo_ed25519")"
export ARGO_SSH_SECRET
ARGO_SSH_PUBKEY="$(cat "${INSTALL_DIR}/argo_ed25519.pub")"

ARGO_AGE_SECRET="$(cat "${INSTALL_DIR}/argo.txt")"
export ARGO_AGE_SECRET

BASE64_ARGO_GIT_URL=$(base64 -w0 < <(echo -n "$ARGO_GIT_URL"))
export BASE64_ARGO_GIT_URL
BASE64_ARGO_AGE_SECRET=$(base64 -w0 < <(echo -n "$ARGO_AGE_SECRET"))
export BASE64_ARGO_AGE_SECRET
BASE64_ARGO_SSH_SECRET=$(base64 -w0 < <(echo -n "$ARGO_SSH_SECRET"))
export BASE64_ARGO_SSH_SECRET

templated_variables=(
	\$CLUSTER_URL
	\$ARGO_GIT_URL
	\$ARGO_GIT_REVISION
	\$BASE64_ARGO_GIT_URL
	\$BASE64_ARGO_AGE_SECRET
	\$BASE64_ARGO_SSH_SECRET
)
vars=$(concat_with_comma "${templated_variables[@]}")

for bootstrap_template in age-secret ssh-keys app-of-apps kustomization; do
	envsubst "$vars" <"bootstrap/template/${bootstrap_template}.yaml.tpl" >"${bootstrap_dir}/${bootstrap_template}.yaml"
done
