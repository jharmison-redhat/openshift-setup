#!/bin/bash

cd "$(dirname "$(realpath "$0")")/.." || exit 1
source hack/common.sh

while read -rd $'\0' ct; do
	decrypt "$ct"
done < <(find "${CLUSTER_DIR}" -maxdepth 3 -type f \( -name secrets.enc.yaml -o -name secrets.enc.yml \) -print0)
