#!/bin/bash

set -e

rhcl_operators=(
  authorino
  dns
  limitador
  rhcl
)

function operator_ready {
  [ "$(oc get -n openshift-operators subscription -l "operators.coreos.com/${1}-operator.openshift-operators" -ojsonpath='{.items[0].status.state}' 2>&1 ||:)" = "AtLatestKnown" ]
}

echo -n 'Waiting for dependencies to be installed'
for operator in "${rhcl_operators[@]}"; do
  if ! operator_ready "$operator"; then
    echo -n '.'
    sleep 1
  fi
done
echo

oc delete pod -n openshift-operators -l app=kuadrant,control-plane=controller-manager
sleep 1
oc rollout status -n openshift-operators deployment/kuadrant-operator-controller-manager
oc apply -f kuadrant.yaml
sleep 1
oc wait --for=condition=Ready kuadrant kuadrant --timeout 15m0s
sleep 1
oc annotate service authorino-authorino-authorization service.beta.openshift.io/serving-cert-secret-name=authorino-server-cert --overwrite
oc patch authorino authorino --type=merge --patch '{"spec": {"listener": {"tls": {"enabled": true, "certSecretRef": {"name": "authorino-server-cert"}}}}}'
