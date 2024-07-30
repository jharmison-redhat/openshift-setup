#!/bin/bash

cd "$(dirname "$(realpath "$0")")/.." || exit 1
source hack/common.sh
templated_variables=(
	\$CLUSTER_URL
	\$ARGO_GIT_URL
	\$ARGO_GIT_REVISION
)
vars=$(concat_with_comma "${templated_variables[@]}")

# Start with our Makefile-provided apps
declare -A applications
for app in $ARGO_APPLICATIONS; do
	applications["$app"]=""
done

# Include any app we have values or secrets for
while read -rd $'\0' values; do
	app="$(basename "$(dirname "$values")")"
	if [[ ! -v applications["$app"] ]]; then
		applications["$app"]=''
	fi
done < <(find clusters -path '*/values/*' -type f \( -name values.yaml -o -name secrets.enc.yaml -o -name secrets.yaml \) -print0)

# Template the apps, update the values references
for app in "${!applications[@]}"; do
	mkdir -p "${CLUSTER_DIR}/applications"
	envsubst "$vars" <"applications-templates/${app}.yaml.tpl" >"${CLUSTER_DIR}/applications/${app}.yaml"
	add_vars=()
	# Always add cluster.yaml if available
	if [ -e "${CLUSTER_DIR}/cluster.yaml" ]; then
		add_vars+=("../../${CLUSTER_DIR}/cluster.yaml")
	fi
	# Add values.yaml for cluster if specified
	if [ -e "${CLUSTER_DIR}/values/${app}/values.yaml" ]; then
		add_vars+=("../../${CLUSTER_DIR}/values/${app}/values.yaml")
	fi
	# Add secrets.enc.yaml via helm-secrets if any secrets exist
	if [ -e "${CLUSTER_DIR}/values/${app}/secrets.yaml" ] || [ -e "${CLUSTER_DIR}/values/${app}/secrets.enc.yaml" ]; then
		add_vars+=("secrets+age-import:///helm-secrets-private-keys/argo.txt?../../${CLUSTER_DIR}/values/${app}/secrets.enc.yaml")
	fi
	for vars_file in "${add_vars[@]}"; do
		hack/yq -i e '.spec.source.helm.valueFiles |= . + ["'"$vars_file"'"]' "${CLUSTER_DIR}/applications/${app}.yaml"
	done
done
