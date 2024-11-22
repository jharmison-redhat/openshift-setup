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
	export HISTFILE="/workdir/install/${CLUSTER_URL}.bash_history"
	export HISTFILESIZE=5000
fi

if [ -n "${INSTALL_DIR}" ]; then
	if [ -e /workdir/.env ]; then
		source /workdir/.env
	fi
	if [ -e "/workdir/${INSTALL_DIR}.env" ]; then
		source "/workdir/${INSTALL_DIR}.env"
	fi
	PATH="/workdir/${INSTALL_DIR}:${PATH}"
	echo "$PATH" | grep -Fq "/root/.krew/bin" || PATH="/root/.krew/bin:$PATH"
	KUBECONFIG="/workdir/${INSTALL_DIR}/auth/kubeconfig"
	export KUBECONFIG

	if ! command -v kubectl >/dev/null 2>&1; then
		if [ -e "/workdir/Makefile" ]; then
			make -C /workdir "${INSTALL_DIR}/kubectl"
		fi
	fi
fi

source <(oc completion bash)
# Only alias oc if we can't connect to the cluster as is, to support plugins
if ! oc whoami >/dev/null 2>&1; then
	if oc --insecure-skip-tls-verify=true whoami >/dev/null 2>&1; then
		alias oc='oc --insecure-skip-tls-verify=true'
		alias k9s='k9s --insecure-skip-tls-verify'
	fi
fi
