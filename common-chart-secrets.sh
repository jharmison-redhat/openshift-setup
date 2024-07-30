# If you want to be able to decrypt secrets, generate your own age key and place it in this array
public_keys=(
	age1px4xaxcy73xdqdrxadc8yecqksf4le3n0l2l9h0xj2m5eneljvwq3asw2h # argocd
	age1ky5amdnkwzj03gwal0cnk7ue7vsd0n64pxm50nxgycssp7vgpqvq9s7lyw # james
)
keystring="$(
	IFS=,
	echo "${public_keys[*]}"
)"

prereqs=(sops age podman)

failed=false
for prereq in "${prereqs[@]}"; do
	if ! command -v "$prereq" &>/dev/null; then
		echo "Prereq $prereq is not found in path - please install it." >&2
		failed=true
	fi
done
if ! command -v sha256sum &>/dev/null; then
	if ! command -v shasum &>/dev/null; then
		echo "Prereq sha256sum or shasum is not found in path - please install one." >&2
		failed=true
	else
		shacmd=(shasum -a 256)
	fi
else
	shacmd=(sha256sum)
fi
if $failed; then
	exit 1
fi

function yq {
	podman run --rm --interactive \
		--security-opt label=disable --user root \
		--volume "${PWD}:/workdir" --workdir /workdir \
		docker.io/mikefarah/yq:latest "${@}"
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
	git add "$ct"
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
