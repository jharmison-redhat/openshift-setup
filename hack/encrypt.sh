#!/bin/bash

cd "$(dirname "$(realpath "$0")")/.." || exit 1
source hack/common.sh

while read -rd $'\0' pt; do
	encrypt "$pt"
done < <(find "${CLUSTER_DIR}" -path '*/values/*' -type f \( -name secrets.yaml -o -name secrets.yml \) -print0)

while read -rd $'\0' ct; do
	rekey "$ct"
done < <(find "${CLUSTER_DIR}" -path '*/values/*' -type f \( -name secrets.enc.yaml -o -name secrets.enc.yml \) -print0)
