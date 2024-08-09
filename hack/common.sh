set -e

for envfile in .env "${INSTALL_DIR}/.env"; do
	if [ -f "$envfile" ]; then source "$envfile"; fi
done

function pull_secret_validate {
	if [ -z "$PULL_SECRET" ]; then
		echo "Please export the PULL_SECRET variable with your cluster pull secret from https://console.redhat.com/openshift/install/platform-agnostic/user-provisioned" >&2
		return 1
	fi
}
function aws_validate {
	if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
		echo "Please export AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY to be able to create a cluster on AWS" >&2
		return 1
	fi
}

function metadata_validate {
	if ! [ -e "${INSTALL_DIR}/metadata.json" ]; then
		echo "No cluster metadata.json, indicating that you probably haven't installed a cluster" >&2
		return 1
	fi
}

function concat_with_comma {
	local IFS=,
	echo "$*"
}

function yq {
	${RUNTIME:-podman} run --rm --interactive \
		--security-opt label=disable --user root \
		--volume "${PWD}:/workdir" --workdir /workdir \
		docker.io/mikefarah/yq:latest "${@}"
}

function oc {
	KUBECONFIG="${INSTALL_DIR}/auth/kubeconfig-orig" "${INSTALL_DIR}/oc" --insecure-skip-tls-verify=true "${@}"
}

if [ -e "${CLUSTER_DIR}/cluster.yaml" ]; then
	infraID=$(yq '.cluster.infraID' "${CLUSTER_DIR}/cluster.yaml")
	aws_cluster_filter="Name=tag:kubernetes.io/cluster/$infraID,Values=owned"
fi

function instances {
	aws ec2 describe-instances --filters "$aws_cluster_filter" --query "Reservations[].Instances[]"
}

function instance_states {
	instances | jq -r '["InstanceId", "State"], (.[] | [.InstanceId, .State.Name]) | @tsv' | column -t
}

function instance_ids {
	instances | jq -r '.[].InstanceId'
}

function _state_instance_ids {
	instances | jq -r '.[] | select(.State.Name == "'"${1:-running}"'") | .InstanceId'
}

function running_instance_ids {
	_state_instance_ids running
}

function stopped_instance_ids {
	_state_instance_ids stopped
}
