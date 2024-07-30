#!/bin/bash

cd "$(dirname "$(realpath "$0")")/.." || exit 1
set -e

function oc {
	KUBECONFIG="${INSTALL_DIR}/auth/kubeconfig-orig" "${INSTALL_DIR}/oc" --insecure-skip-tls-verify=true "${@}"
}

cluster_yaml="${CLUSTER_DIR}/cluster.yaml"
if [ -e "$cluster_yaml" ] && (! git ls-files --error-unmatch "$cluster_yaml"); then
	echo "Please commit changes for $CLUSTER_URL before applying bootstrap" >&2
	exit 1
fi

timeout=1800
step=5
duration=0
echo -n "Applying bootstrap"
while true; do
	if ((duration >= timeout)); then
		exit 1
	fi
	if oc apply -k "${INSTALL_DIR}/bootstrap" >/dev/null 2>&1; then
		break
	fi
	sleep "$step"
	echo -n .
	((duration += step))
done
echo
sed -i '/certificate-authority-data/d' "${INSTALL_DIR}/auth/kubeconfig"
