#!/usr/bin/env bash

cd "$(dirname "$(realpath "$0")")/.." || exit 1
source hack/common.sh

mapfile -t stopped < <(stopped_instance_ids)
if [ "${stopped[*]}" ]; then
  failed_instances=()
  for instance in "${stopped[@]}"; do
	  if ! aws ec2 start-instances --instance-ids "${instance}" --output table --no-cli-pager; then
      failed_instances+=("$instance")
    fi
  done
  echo "Failed to start instances: ${failed_instances[*]}"
else
	echo "No stopped instances:"
	instance_states | sed 's/^/  /'
fi
