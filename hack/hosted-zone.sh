#!/bin/bash

cd "$(dirname "$(realpath "$0")")/.." || exit 1
source hack/common.sh

aws_validate
aws_validate_functional

hosted_zone="${BASE_DOMAIN}."

echo -n 'Checking for existing HostedZone'
found=false
for zone in $(aws route53 list-hosted-zones --output text --query "HostedZones[].Name"); do
	if [ "$zone" = "$hosted_zone" ]; then
		found=true
		break
	fi
    echo -n .
done
echo

if ! $found; then
    change=$(aws route53 create-hosted-zone --name "${hosted_zone}" --caller-reference "$(date -Iseconds)")
    change_id=$(echo "$change" | jq -r '.ChangeInfo.Id' | cut -d/ -f3)
    echo -n "Creating HostedZone for ${BASE_DOMAIN}"
    while [ "$(aws route53 get-change --id "$change_id" --query "ChangeInfo.Status" --output text 2>/dev/null)" != "INSYNC" ]; do
        echo -n .
        sleep 1
    done
    echo
fi


echo -n 'Retrieving HostedZone configuration'
hosted_zone_id=$(aws route53 list-hosted-zones --output text --query "HostedZones[?Name == '${hosted_zone}'].Id | [0]" | cut -d/ -f3)
echo -n .

# shellcheck disable=SC2207
hz_nameservers=( $(aws route53 get-hosted-zone --id "$hosted_zone_id" --query DelegationSet.NameServers --output text) )
echo .

if [ -n "$ROOT_AWS_ACCESS_KEY_ID" ] && [ -n "$ROOT_AWS_SECRET_ACCESS_KEY" ]; then
    # Check if the record exists to point to BASE_DOMAIN's nameservers
    function root_aws {
        AWS_ACCESS_KEY_ID="$ROOT_AWS_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$ROOT_AWS_SECRET_ACCESS_KEY" aws "${@}"
    }
    root_hosted_zone=$(echo "${hosted_zone}" | cut -d. -f2-)
    echo -n "Validating configuration in root HostedZone (${root_hosted_zone/%./})"
    root_hosted_zone_id=$(root_aws route53 list-hosted-zones --output text --query "HostedZones[?Name == '${root_hosted_zone}'].Id | [0]" | cut -d/ -f3)
    echo -n .
    # shellcheck disable=SC2207
    root_hz_nameservers=( $(root_aws route53 list-resource-record-sets --hosted-zone-id "${root_hosted_zone_id}" --query "ResourceRecordSets[?Name == '${hosted_zone}'] | [?Type == 'NS'].ResourceRecords[].Value" --output text) )
    echo -n .

    nameserver_unspecified=false
    for hz_nameserver in "${hz_nameservers[@]}"; do
        if [[ " ${root_hz_nameservers[*]} " =~ [[:space:]]${hz_nameserver}.[[:space:]] ]]; then
            break
        fi
        nameserver_unspecified=true
    done
    echo

    if $nameserver_unspecified; then
        echo TODO: update the root hosted zone with the NS records
    fi
else
    echo TODO: check if the NS for the base domain is accurate
    # dig -t NS @1.1.1.1 "${BASE_DOMAIN}" | grep -qF ''
fi
