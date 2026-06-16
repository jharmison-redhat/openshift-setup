#!/bin/bash

set -e

rhcl_operators=(
  authorino
  dns
  limitador
  rhcl
)

operator_namespace={{ (index (index $.Values "install-rhcl").operators "rhcl-operator").namespace | default "openshift-operators" }}

function operator_ready {
  [ "$(oc get -n $operator_namespace subscription -l "operators.coreos.com/${1}-operator.openshift-operators" -ojsonpath='{.items[0].status.state}' 2>&1 ||:)" = "AtLatestKnown" ]
}

echo -n 'Waiting for dependencies to be installed'
for operator in "${rhcl_operators[@]}"; do
  if ! operator_ready "$operator"; then
    echo -n '.'
    sleep 1
  fi
done
echo

oc delete pod -n $operator_namespace -l app=kuadrant,control-plane=controller-manager
sleep 1
oc rollout status -n $operator_namespace deployment/kuadrant-operator-controller-manager
