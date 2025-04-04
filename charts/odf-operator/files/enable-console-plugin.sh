#!/bin/bash

function noisy {
    set -x
    "${@}"
    { set +x; } 2>/dev/null
}
PLUGIN_NAME="${PLUGIN_NAME:-odf-console}"

echo "Ensuring ${PLUGIN_NAME} plugin is enabled"
echo ""

# Create the plugins section on the object if it doesn't exist
if [ -z "$(oc get consoles.operator.openshift.io cluster -o=jsonpath='{.spec.plugins}' 2>/dev/null)" ]; then
    echo "Creating plugins object"
    noisy oc patch consoles.operator.openshift.io cluster --patch '{ "spec": { "plugins": [] } }' --type=merge
fi

installed_plugins=$(oc get consoles.operator.openshift.io cluster -o=jsonpath='{.spec.plugins}')
echo "Current plugins:"
echo "${installed_plugins}"

if [[ "${installed_plugins}" == *"${PLUGIN_NAME}"* ]]; then
    echo "${PLUGIN_NAME} is already enabled"
else
    echo "Enabling plugin: ${PLUGIN_NAME}"
    noisy oc patch consoles.operator.openshift.io cluster --type=json --patch '[{"op": "add", "path": "/spec/plugins/-", "value": "'"${PLUGIN_NAME}"'"}]'
fi

sleep 6
noisy oc get consoles.operator.openshift.io cluster -o=jsonpath='{.spec.plugins}'
