function _last_failed {
	local last_exit=$?
	if [ "$last_exit" -gt 0 ]; then
		printf ' \e[0;31m✗\e[0m('"${last_exit})\n"
	fi
}
PROMPT_COMMAND=_last_failed

PS1='[openshift-setup \w]$ '
if [ -n "${CLUSTER_URL}" ]; then
	PS1="(${CLUSTER_URL}) ${PS1}"
fi

if [ -n "${INSTALL_DIR}" ]; then
	PATH="/workdir/${INSTALL_DIR}:${PATH}"
	KUBECONFIG="/workdir/${INSTALL_DIR}/auth/kubeconfig-orig"
	export KUBECONFIG

	if ! command -v oc >/dev/null 2>&1; then
		if [ -e "/workdir/Makefile" ]; then
			make -C /workdir "${INSTALL_DIR}/oc"
		fi
	fi
fi

source <(oc completion bash)
alias oc='oc --insecure-skip-tls-verify=true'
alias k9s='k9s --insecure-skip-tls-verify'
