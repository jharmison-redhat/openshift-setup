#!/bin/bash

cd "$(dirname "$(realpath "$0")")/.." || exit 1
source hack/common.sh

metadata_validate

mkdir -p "${CLUSTER_DIR}/applications"

infraID="$(jq -r '.infraID' "${INSTALL_DIR}/metadata.json")"
region="$(jq -r '.aws.region' "${INSTALL_DIR}/metadata.json")"
azs="$(jq -c '.aws_worker_availability_zones' "${INSTALL_DIR}/terraform.platform.auto.tfvars.json")"
ami="$(jq -r '.aws_ami' "${INSTALL_DIR}/terraform.platform.auto.tfvars.json")"
age_public_key="$(awk '/public key:/{print $NF}' "${INSTALL_DIR}/argo.txt")"

cat <<EOF >"${CLUSTER_DIR}/cluster.yaml"
---
cluster:
  infraID: $infraID
  name: $CLUSTER_NAME
  baseDomain: $BASE_DOMAIN
  controlPlaneNodes: $CONTROL_PLANE_COUNT
  workerNodes: $WORKER_COUNT
  agePublicKey: $age_public_key
aws:
  region: $region
  azs: $azs
  ami: $ami
desiredUpdate:
  version: $CLUSTER_VERSION
EOF

mkdir -p "${CLUSTER_DIR}/values/cert-manager"
cat <<EOF >"${CLUSTER_DIR}/values/cert-manager/values.yaml"
certificates:
  clusterIssuer: letsencrypt
acme:
  letsencrypt:
    server: https://acme-v02.api.letsencrypt.org/directory
    disableAccountKeyGeneration: ${ACME_DISABLE_ACCOUNT_KEY_GENERATION:-true}
    privateKeySecretRef:
      name: letsencrypt-private-key
EOF
cat <<EOF >"${CLUSTER_DIR}/values/cert-manager/secrets.yaml"
---
acme:
  letsencrypt:
    email: ${ACME_EMAIL}
    secrets:
      - name: route53-creds
        stringData:
          secret-access-key: ${AWS_SECRET_ACCESS_KEY}
    solvers:
      - type: dns
        dnsConfig:
          route53:
            accessKeyID: ${AWS_ACCESS_KEY_ID}
            hostedZoneId: $(aws_hosted_zone_id)
            region: ${AWS_REGION}
            secretAccessKeySecretRef:
              key: secret-access-key
              name: acme-letsencrypt-route53-creds
        dnsZones:
          - ${BASE_DOMAIN}
EOF
