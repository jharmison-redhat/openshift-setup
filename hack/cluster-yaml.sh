#!/bin/bash

cd "$(dirname "$(realpath "$0")")/.." || exit 1
source hack/common.sh

metadata_validate

cluster_dir="clusters/${CLUSTER_URL}"
mkdir -p "$cluster_dir/applications"

infraID="$(jq -r '.infraID' "${INSTALL_DIR}/metadata.json")"
region="$(jq -r '.aws.region' "${INSTALL_DIR}/metadata.json")"
azs="$(jq -c '.aws_worker_availability_zones' "${INSTALL_DIR}/terraform.platform.auto.tfvars.json")"
ami="$(jq -r '.aws_ami' "${INSTALL_DIR}/terraform.platform.auto.tfvars.json")"
age_public_key="$(awk '/public key:/{print $NF}' "${INSTALL_DIR}/argo.txt")"

cat <<EOF >"$cluster_dir/cluster.yaml"
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
