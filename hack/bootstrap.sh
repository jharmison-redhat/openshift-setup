#!/bin/bash

cd "$(dirname "$(realpath "$0")")/.." || exit 1
source hack/common.sh

if ! cluster_files_updated; then
	mapfile -t uncommitted < <(git status -su "${CLUSTER_DIR}" | awk '{print $NF}')
	mapfile -t unpushed < <(git diff --name-only "@{u}...HEAD" -- "${CLUSTER_DIR}")
	declare -A needs_update
	for file in "${uncommitted[@]}" "${unpushed[@]}"; do
		needs_update["$file"]=""
	done
	echo "The following files need to be committed or pushed for bootstrap:" >&2
	printf '  %s\n' "${!needs_update[@]}" >&2
	exit 1
fi

if ! argo_ssh_validate; then
	echo "Unable to authenticate to github.com with your ArgoCD key - did you configure the deploy key?" >&2
	cat "${INSTALL_DIR}/argo_ed25519.pub"
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

echo "Deleting hanging installer pods that remain in failed state"
oc delete pod --selector=app=installer --field-selector=status.phase=Failed --all-namespaces
