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
            hostedZoneID: $(aws_hosted_zone_id)
            region: ${AWS_REGION}
            secretAccessKeySecretRef:
              key: secret-access-key
              name: acme-letsencrypt-route53-creds
        dnsZones:
          - ${BASE_DOMAIN}
EOF

mkdir -p "${CLUSTER_DIR}/values/oauth"
if [ ! -f "${CLUSTER_DIR}/values/oauth/secrets.yaml" ]; then
	read -n1 -rp "Do you want to configure a GitHub OAuth application (y/N)? " make_oauth
	echo
	if [ "${make_oauth^^}" = "Y" ]; then
		echo "Set the name to:"
		echo "  ${CLUSTER_URL}"
		echo "Set the homepage to:"
		echo "  https://console-openshift-console.apps.${CLUSTER_URL}"
		echo "Set the callback-url to:"
		echo "  https://oauth-openshift.apps.${CLUSTER_URL}/oauth2callback/github"
		echo
		read -rp "Enter your OAuth App organization: " org
		read -rp "Enter your OAuth App Client ID: " client_id
		read -srp "Enter your OAuth App Client Secret: " client_secret
		echo
		read -rp "Enter your GitHub user accounts for administrator access, separated by spaces: " admins
		cat <<EOF >"${CLUSTER_DIR}/values/oauth/values.yaml"
---
providers:
  htpasswd: null
  github:
    organizations:
      - ${org}

admins:
$(for admin in $admins; do echo "  - $admin"; done)
EOF
		cat <<EOF >"${CLUSTER_DIR}/values/oauth/secrets.yaml"
---
providers:
  github:
    clientId: $client_id
    clientSecret: $client_secret
EOF
	else
		admin_pw=$(genpasswd)
		developer_pw=$(genpasswd)
		cat <<EOF >"${CLUSTER_DIR}/values/oauth/secrets.yaml"
---
providers:
  htpasswd:
    admin: "${admin_pw}"
    developer: "${developer_pw}"
EOF
		echo "Your generated passwords are:"
		echo "  admin: ${admin_pw}"
		echo "  developer: ${developer_pw}"
	fi
fi
