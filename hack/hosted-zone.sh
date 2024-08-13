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
	echo -n "Creating HostedZone for ${BASE_DOMAIN}"
	change=$(aws route53 create-hosted-zone --name "${hosted_zone}" --caller-reference "$(date -Iseconds)")
	change_id=$(echo "$change" | jq -r '.ChangeInfo.Id' | cut -d/ -f3)
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
hz_nameservers=($(aws route53 get-hosted-zone --id "$hosted_zone_id" --query DelegationSet.NameServers --output text))
echo .

root_hosted_zone=$(echo "${hosted_zone}" | cut -d. -f2-)

function public_dns_validation {
	echo "Validating configuration of public NS records in root domain (${root_hosted_zone/%./})."
	# shellcheck disable=SC2207
	public_nameservers=($(dig -t NS @1.1.1.1 +short "${BASE_DOMAIN}"))
	nameserver_unspecified=false
	for hz_nameserver in "${hz_nameservers[@]}"; do
		if [[ " ${public_nameservers[*]} " =~ [[:space:]]${hz_nameserver}.[[:space:]] ]]; then
			continue
		fi
		nameserver_unspecified=true
		break
	done
	if $nameserver_unspecified; then
		echo "Unable to continue, can't validate ${BASE_DOMAIN} HostedZone NS records in root domain." >&2
		printf "  %s.\n" "${hz_nameservers[@]}"
		exit 1
	else
		echo "Records are configured correctly for ${hosted_zone}"
	fi
}

if [ -n "$ROOT_AWS_ACCESS_KEY_ID" ] && [ -n "$ROOT_AWS_SECRET_ACCESS_KEY" ]; then
	# Check if the record exists to point to BASE_DOMAIN's nameservers
	function root_aws {
		AWS_ACCESS_KEY_ID="$ROOT_AWS_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$ROOT_AWS_SECRET_ACCESS_KEY" aws "${@}"
	}
	echo -n "Validating configuration in root HostedZone (${root_hosted_zone/%./})"
	root_hosted_zone_id=$(root_aws route53 list-hosted-zones --output text --query "HostedZones[?Name == '${root_hosted_zone}'].Id | [0]" 2>/dev/null | cut -d/ -f3)
	if [ -z "${root_hosted_zone_id}" ] || [ "${root_hosted_zone_id}" = "None" ]; then
		echo
		echo "ROOT_AWS_ACCESS_KEY_ID and ROOT_AWS_SECRET_ACCESS_KEY appear to be not valid for managing records in ${root_hosted_zone} Attempting DNS lookup." >&2
		public_dns_validation
	fi
	echo -n .
	# shellcheck disable=SC2207
	root_hz_nameservers=($(root_aws route53 list-resource-record-sets --hosted-zone-id "${root_hosted_zone_id}" --query "ResourceRecordSets[?Name == '${hosted_zone}'] | [?Type == 'NS'].ResourceRecords[].Value" --output text))
	echo -n .

	nameserver_unspecified=false
	for hz_nameserver in "${hz_nameservers[@]}"; do
		if [[ " ${root_hz_nameservers[*]} " =~ [[:space:]]${hz_nameserver}.[[:space:]] ]]; then
			continue
		fi
		nameserver_unspecified=true
		break
	done
	echo

	if $nameserver_unspecified; then
		echo -n "Updating ${root_hosted_zone/%./} with NS records for ${hosted_zone}"
		function generate-records {
			for record in "${hz_nameservers[@]}"; do
				echo '          {"Value": "'"${record}."'"},'
			done | head -c -2
			echo
		}
		change=$(root_aws route53 change-resource-record-sets --hosted-zone-id "${root_hosted_zone_id}" --change-batch file://<(
			cat <<EOF
{
  "Comment": "Record created for ${BASE_DOMAIN} cluster by openshift-setup $(date -Iseconds)",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${hosted_zone}",
        "Type": "NS",
        "TTL": 300,
        "ResourceRecords": [
$(generate-records)
        ]
    }
    }
  ]
}
EOF
		))
		change_id=$(echo "$change" | jq -r '.ChangeInfo.Id' | cut -d/ -f3)
		while [ "$(root_aws route53 get-change --id "$change_id" --query "ChangeInfo.Status" --output text 2>/dev/null)" != "INSYNC" ]; do
			echo -n .
			sleep 1
		done
		echo
	else
		echo "Records are configured correctly for ${hosted_zone}"
	fi
else
	public_dns_validation
fi
