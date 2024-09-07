#!/bin/bash

cd "$(dirname "$(realpath "$0")")/.." || exit 1
source hack/common.sh

if ! oc whoami >/dev/null 2>&1; then
	echo "Unable to confirm authentication to $(oc whoami --show-server)" >&2
	exit 1
fi

echo -n 'Waiting for Certificate Signing Requests to approve'
while :; do
	while oc get csr 2>/dev/null | grep -qF Pending; do
		echo
		oc get csr -ojson |
			jq -r '.items[] | select(.status == {}) | .metadata.name' |
			xargs --max-procs=0 --max-args=1 --verbose --no-run-if-empty \
				"${INSTALL_DIR}/oc" --insecure-skip-tls-verify=true --kubeconfig="${INSTALL_DIR}/auth/kubeconfig-orig" adm certificate approve
		echo
		echo -n 'Waiting for more CSRs'
	done
	sleep 5
	echo -n '.'
done
