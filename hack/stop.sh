#!/bin/bash

cd "$(dirname "$(realpath "$0")")/.." || exit 1
source hack/common.sh

mapfile -t running < <(running_instance_ids)
if [ "${running[*]}" ]; then
	aws ec2 stop-instances --instance-ids "${running[@]}" --output table
else
	echo "No running instances:"
	instance_states | sed 's/^/  /'
fi
