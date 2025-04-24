#!/bin/bash

cd "$(dirname "$(realpath "$0")")/.." || exit 1
source hack/common.sh

# Start with our Makefile- and env-provided apps
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
        if [ -e "applications-templates/${app}.yaml.tpl" ]; then
            applications["$app"]=''
        else
            echo "No application template available, skipping..." >&2
        fi
    fi
done < <(find "${CLUSTER_DIR}" -path '*/values/*' -type f \( -name values.yaml -o -name values.yml -o -name secrets.enc.yaml -o -name secrets.enc.yml \) -print0)

mkdir -p "${CLUSTER_DIR}/applications"
# Template the apps, update the values references
for app in "${!applications[@]}"; do
    /usr/local/bin/openshift-setup app process "applications-templates/${app}.yaml.tpl"
done
