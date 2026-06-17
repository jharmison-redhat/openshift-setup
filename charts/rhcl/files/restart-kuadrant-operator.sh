#!/bin/bash

set -ex

rhcl_operators=(
  authorino
  dns
  limitador
  rhcl
)

operator_namespace={{ (index (index $.Values "install-rhcl").operators "rhcl-operator").namespace | default "openshift-operators" }}

function operator_ready {
  installed_version="$(oc get -n $operator_namespace subscription -l "operators.coreos.com/${1}-operator.${operator_namespace}" -ojsonpath='{.items[0].status.installedCSV}' 2>&1)" ||:
  if [ "$installed_version" != "" ]; then
    return 0
  else
    return 1
  fi
}

for operator in "${rhcl_operators[@]}"; do
  if ! operator_ready "$operator"; then
    sleep 1
  fi
done
echo

oc delete pod -n $operator_namespace -l app=kuadrant,control-plane=controller-manager
sleep 1
oc rollout status -n $operator_namespace deployment/kuadrant-operator-controller-manager
