set -e

COMMON_PUBLIC_KEYS=(
	age1ky5amdnkwzj03gwal0cnk7ue7vsd0n64pxm50nxgycssp7vgpqvq9s7lyw # jharmison@redhat.com
)

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

function aws_validate_functional {
	if ! aws sts get-caller-identity >/dev/null 2>&1; then
		echo "AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY appear not be valid" >&2
		return 2
	fi
}

function metadata_validate {
	if ! [ -e "${INSTALL_DIR}/metadata.json" ]; then
		echo "No cluster metadata.json, indicating that you probably haven't installed a cluster" >&2
		return 1
	fi
}

function argo_ssh_validate {
	{ ssh -i "${INSTALL_DIR}/argo_ed25519" -o IdentityAgent=none -o IdentitiesOnly=yes git@github.com 2>&1 || :; } | grep -qF 'successfully authenticated'
}

function cluster_file_pushed {
	git diff --quiet "@{u}...HEAD" -- "${@}" || return 1
}

function cluster_file_committed {
	if [ "$(git status -s -uall "${@}")" ]; then return 1; fi
}

function cluster_files_updated {
	ret=0
	while read -rd $'\0' cluster_file; do
		if ! cluster_file_committed "${cluster_file}"; then
			echo "uncommitted changes: $cluster_file" >&2
			((ret += 1))
			continue
		fi
		if ! cluster_file_pushed "${cluster_file}"; then
			echo "unpushed changes: ${cluster_file}" >&2
			((ret += 1))
		fi
	done < <(find "${CLUSTER_DIR}" -type f \( ! -name 'secrets.yaml' -a ! -name 'secrets.yml' \) -print0)
	return "$ret"
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
	age_public_key=$(yq '.cluster.agePublicKey' "${CLUSTER_DIR}/cluster.yaml")
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

function ct_needs_update {
	pt="$1"
	ct="$2"
	# If ciphertext doesn't exist, we need to generate it
	if [ ! -f "$ct" ]; then
		sops --encrypt --age "$keystring" "$pt" | yq e
		return 0
	fi
	# If the plaintext is modified more recently, we need to check if it's the same
	if [ "$pt" -nt "$ct" ]; then
		pt_content="$(sops --decrypt "$ct" | yq e)"
		sha256sum="$(echo "$pt_content" | "${shacmd[@]}" | cut -d' ' -f1)"
		# If we need to update the plaintext, return the content
		if ! echo "$sha256sum  $pt" | "${shacmd[@]}" -c - >/dev/null 2>&1; then
			sops --encrypt --age "$keystring" "$pt" | yq e
			return 0
		fi
	fi
	# If none of those is true, we need no update
	return 1
}

public_keys=("${COMMON_PUBLIC_KEYS[@]}" "${age_public_key}")
keystring="$(
	IFS=,
	echo "${public_keys[*]}"
)"

function encrypt {
	pt="$1"
	# Build out the ciphertext name
	dir="$(dirname "$pt")"
	fn="$(basename "$pt")"
	ext="${fn##*.}"
	fn="${fn%.*}"
	ct="$dir/$fn.enc.$ext"

	# If no update is necessary just continue to the next file
	if ! content=$(ct_needs_update "$pt" "$ct"); then
		return
	fi
	echo "Updating $ct" >&2
	echo "$content" >"$ct"
}

function pt_needs_update {
	pt="$1"
	ct="$2"

	# If plaintext doesn't exist, we need to generate it
	if [ ! -f "$pt" ]; then
		sops --decrypt "$ct" | yq e
		return 0
	fi
	# If the ciphertext is modified more recently, we need to check if we have to update the content
	if [ "$ct" -nt "$pt" ]; then
		content="$(sops --decrypt "$ct" | yq e)"
		sha256sum="$(echo "$content" | "${shacmd[@]}" | cut -d' ' -f1)"
		# If we need to update the plaintext, return the content
		if ! echo "$sha256sum  $pt" | "${shacmd[@]}" -c - >/dev/null 2>&1; then
			echo "$content"
			return 0
		fi
	fi
	# If none of that is true, we need no update
	return 1
}

function decrypt {
	ct="$1"
	pt="${ct//\.enc/}"
	# If no update is necessary just continue to the next file
	if ! content=$(pt_needs_update "$pt" "$ct"); then
		return
	fi
	echo "Updating $pt" >&2
	echo "$content" >"$pt"
}

function rekey {
	ct="$1"
	pt="${ct//\.enc/}"

	# If the recipients have changed, we need to reencrypt
	recipients=$(yq e '.sops.age | map(.recipient) | join(",")' <"$ct")
	if [ "$recipients" != "$keystring" ]; then
		# Ensure we have the latest version of the PT
		decrypt "$ct"
		echo "Rekeying $ct" >&2
		sops --encrypt --age "$keystring" "$pt" | yq e >"$ct"
		git add "$ct"
	fi
}
