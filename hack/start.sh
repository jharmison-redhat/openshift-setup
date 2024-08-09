#!/bin/bash

cd "$(dirname "$(realpath "$0")")/.." || exit 1
source hack/common.sh

mapfile -t stopped < <(stopped_instance_ids)
if [ "${stopped[*]}" ]; then
	aws ec2 start-instances --instance-ids "${stopped[@]}" --output table
else
	echo "No stopped instances:"
	instance_states | sed 's/^/  /'
fi
