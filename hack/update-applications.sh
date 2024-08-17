#!/bin/bash

cd "$(dirname "$(realpath "$0")")/.." || exit 1
source hack/common.sh

# Preemptively encrypt any secrets
hack/encrypt.sh

# Start with our Makefile-provided apps
declare -A applications
for app in $ARGO_APPLICATIONS; do
	echo "Found $app in ARGO_APPLICATIONS" >&2
	applications["$app"]=""
done

# Include any app we have values or secrets for
while read -rd $'\0' values; do
	app="$(basename "$(dirname "$values")")"
	if [[ ! -v applications["$app"] ]]; then
		echo "Found $app in values from $values" >&2
		applications["$app"]=''
	fi
done < <(find "${CLUSTER_DIR}" -path '*/values/*' -type f \( -name values.yaml -o -name values.yml -o -name secrets.enc.yaml -o -name secrets.enc.yml \) -print0)

# Save notes from apps
declare -A notes

# Set vars for app templates
templated_variables=(
	\$CLUSTER_URL
	\$ARGO_GIT_URL
	\$ARGO_GIT_REVISION
)
vars=$(concat_with_comma "${templated_variables[@]}")

mkdir -p "${CLUSTER_DIR}/applications"
# Template the apps, update the values references
for app in "${!applications[@]}"; do
	app_yaml="${CLUSTER_DIR}/applications/${app}.yaml"
	values_dir="${CLUSTER_DIR}/values/${app}"
	echo "Re-templating $app_yaml" >&2
	envsubst "$vars" <"applications-templates/${app}.yaml.tpl" >"$app_yaml"
	if grep -q '^# NOTE:' "$app_yaml"; then
		notes["$app"]="$(grep '^# NOTE:' "$app_yaml" | cut -d' ' -f3-)"
	fi
	add_vars=()
	# Always add cluster.yaml if available
	if [ -e "${CLUSTER_DIR}/cluster.yaml" ]; then
		add_vars+=("../../${CLUSTER_DIR}/cluster.yaml")
	fi

	# Add values.yaml for app if specified
	if [ -e "${values_dir}/values.yaml" ]; then
		add_vars+=("../../${values_dir}/values.yaml")
	fi
	if [ -e "${values_dir}/values.yml" ]; then
		add_vars+=("../../${values_dir}/values.yml")
	fi

	# Add secrets.enc.yaml via helm-secrets if app secrets are specified
	if [ -e "${values_dir}/secrets.enc.yaml" ]; then
		add_vars+=("secrets+age-import:///helm-secrets-private-keys/argo.txt?../../${values_dir}/secrets.enc.yaml")
	fi
	if [ -e "${values_dir}/secrets.enc.yml" ]; then
		add_vars+=("secrets+age-import:///helm-secrets-private-keys/argo.txt?../../${values_dir}/secrets.enc.yml")
	fi

	for vars_file in "${add_vars[@]}"; do
		yq -i e '.spec.source.helm.valueFiles |= . + ["'"$vars_file"'"]' "$app_yaml"
	done
done

# Output any app notes
for app in "${!notes[@]}"; do
	echo "$app notes:"
	echo "${notes[$app]}"
done
