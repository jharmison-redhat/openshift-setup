#!/bin/bash

cd "$(dirname "$(realpath "$0")")/.." || exit 1
source hack/common.sh

if cluster_validate && (! metadata_validate >/dev/null 2>&1); then # We are adopting a cluster
	infra=$(oc get infrastructure cluster -ojson)
	function infra_get {
		echo "$infra" | jq -r "${@}"
	}
	if [ "$(infra_get '.spec.platformSpec.type == "AWS"')" = true ]; then # We have an AWS cluster
		infraID="$(infra_get '.status.infrastructureName')"
		region="$(infra_get '.status.platformStatus.aws.region')"
		if aws_validate_functional; then # we have valid AWS creds to query with
			filter=(--filters "Name=tag-key,Values=kubernetes.io/cluster/$infraID")
			azs="$(AWS_REGION=$region aws ec2 describe-subnets "${filter[@]}" | jq -c '[.Subnets[].AvailabilityZone] | unique')"
			ami="$(AWS_REGION=$region aws ec2 describe-instances "${filter[@]}" | jq -r '.Reservations[].Instances[].ImageId' | head -1)"
		fi
		CONTROL_PLANE_COUNT="$(oc get machine -n openshift-machine-api -l machine.openshift.io/cluster-api-machine-role=master --no-headers 2>/dev/null | wc -l)"
		export CONTROL_PLANE_COUNT
		WORKER_COUNT="$(oc get machine -n openshift-machine-api -l machine.openshift.io/cluster-api-machine-role=worker --no-headers 2>/dev/null | wc -l)"
		export WORKER_COUNT
	fi
elif metadata_validate; then
	infraID="$(jq -r '.infraID' "${INSTALL_DIR}/metadata.json")"
	region="$(jq -r '.aws.region' "${INSTALL_DIR}/metadata.json")"
	azs="$(jq -c '.aws_worker_availability_zones' "${INSTALL_DIR}/terraform.platform.auto.tfvars.json")"
	ami="$(jq -r '.aws_ami' "${INSTALL_DIR}/terraform.platform.auto.tfvars.json")"
else
	echo Unable to generate cluster.yaml >&2
	exit 1
fi

mkdir -p "${CLUSTER_DIR}/applications"

age_public_key="$(awk '/public key:/{print $NF}' "${INSTALL_DIR}/argo.txt")"

# Template cert-manager if desired and able
if [ -n "$ACME_EMAIL" ] && [[ $ARGO_APPLICATIONS =~ "cert-manager" ]] && [ -n "${AWS_ACCESS_KEY_ID}" ] && [ -n "${AWS_SECRET_ACCESS_KEY}" ]; then
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
            region: ${AWS_REGION:-us-east-2}
            secretAccessKeySecretRef:
              key: secret-access-key
              name: acme-letsencrypt-route53-creds
        dnsZones:
          - ${BASE_DOMAIN}
EOF
fi

mkdir -p "${CLUSTER_DIR}/values/oauth"
if [ ! -f "${CLUSTER_DIR}/values/oauth/secrets.yaml" ]; then
	read -n1 -rp "Do you want to configure a GitHub OAuth application (y/N)? " make_oauth
	echo
	if [ "${make_oauth^^}" = "Y" ]; then # Desired GitHub OAuth setup
		read -rp "Enter the GitHub organization for your OAuth application: " org
		echo
		echo "Check for an existing OAuth application at:"
		echo "  https://github.com/organizations/${org}/settings/applications"
		echo "If you don't see one for ${CLUSTER_URL}, then create a new one."
		echo "Set the name to:"
		echo "  ${CLUSTER_URL}"
		echo "Set the homepage to:"
		echo "  https://console-openshift-console.apps.${CLUSTER_URL}"
		echo "Set the callback-url to:"
		echo "  https://oauth-openshift.apps.${CLUSTER_URL}/oauth2callback/github"
		echo
		read -rp "Enter your OAuth App Client ID: " client_id
		read -srp "Enter your OAuth App Client Secret: " client_secret
		echo
		read -rp "Enter your GitHub user accounts for administrator access, separated by spaces: " admins
		cat <<EOF >"${CLUSTER_DIR}/values/oauth/values.yaml"
providers:
  htpasswd: null
  github:
    organizations:
      - ${org}

admins:
$(for admin in $admins; do echo "  - $admin"; done)
EOF
		cat <<EOF >"${CLUSTER_DIR}/values/oauth/secrets.yaml"
providers:
  github:
    clientId: $client_id
    clientSecret: $client_secret
EOF
	else # No desire for GitHub OAuth
		admin_pw=$(genpasswd 32)
		developer_pw=$(genpasswd 32)
		cat <<EOF >"${CLUSTER_DIR}/values/oauth/secrets.yaml"
providers:
  htpasswd:
    admin: "${admin_pw}"
    developer: "${developer_pw}"
EOF
		echo "Your generated passwords are:"
		echo "  admin: ${admin_pw}"
		echo "  developer: ${developer_pw}"
	fi # end of GH OAuth
fi  # end of OAuth secrets exist

cat <<EOF >"${CLUSTER_DIR}/cluster.yaml"
desiredUpdate:
  version: $CLUSTER_VERSION
cluster:
  name: $CLUSTER_NAME
  baseDomain: $BASE_DOMAIN
  controlPlaneNodes: $CONTROL_PLANE_COUNT
  workerNodes: $WORKER_COUNT
  agePublicKey: $age_public_key
EOF

if [ -n "$infraID" ] && [ -n "$region" ] && [ -n "$azs" ] && [ -n "$ami" ]; then
	cat <<EOF >>"${CLUSTER_DIR}/cluster.yaml"
  infraID: $infraID
aws:
  region: $region
  azs: $azs
  ami: $ami
EOF
fi
