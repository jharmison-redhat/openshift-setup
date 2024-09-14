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
	-v "$PWD:/workdir" -v ~/.config:/root/.config --env-host \
	--env HOME=/root --env EDITOR=vi --env XDG_CONFIG_HOME=/root/.config \
	--pull=newer --name openshift-setup --replace --entrypoint /bin/bash \
	"${IMAGE:-registry.jharmison.com/library/openshift-setup:latest}" -li
