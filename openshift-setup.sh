#!/bin/bash

if [ -f .env ]; then
	source .env
fi
export CLUSTER_NAME="${CLUSTER_NAME:-cluster}"
export BASE_DOMAIN="${BASE_DOMAIN:-demo.jharmison.dev}"
export CLUSTER_URL="${CLUSTER_NAME}.${BASE_DOMAIN}"
export CLUSTER_DIR="clusters/${CLUSTER_URL}"
export INSTALL_DIR="install/${CLUSTER_URL}"
cluster_env="${INSTALL_DIR}.env"

if [ -f "$cluster_env" ]; then
	source "$cluster_env"
fi
exec ${RUNTIME:-podman} run --rm -it --security-opt=label=disable --privileged \
	--pull=newer --name openshift-setup --replace --entrypoint /bin/bash \
	-v "$PWD:/workdir" -v ~/.config:/root/.config --env-file .env \
	--env-file "$PWD/${INSTALL_DIR}.env" --env HOME=/root --env EDITOR=vi \
	--env CLUSTER_NAME="$CLUSTER_NAME" --env BASE_DOMAIN="$BASE_DOMAIN" \
	--env CLUSTER_URL="$CLUSTER_URL" --env CLUSTER_DIR="$CLUSTER_DIR" \
	--env INSTALL_DIR="$INSTALL_DIR" --env XDG_CONFIG_HOME=/root/.config \
	--env XDG_DATA_DIR="/workdir/${INSTALL_DIR}/.data" \
	"${IMAGE:-registry.jharmison.com/library/openshift-setup:latest}" -li
