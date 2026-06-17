#!/bin/bash

{{- $operator := index . 0 }}
{{- $config := index . 1 }}
{{- $approveCSVs := $config.approveCSVs | default list }}
{{- $manualInstall := eq ($config.installPlanApproval | default "Automatic") "Manual" }}
{{- if $manualInstall }}
{{- $approveCSVs = append $approveCSVs $config.startingCSV }}
{{- end }}

function approve_install_plan {
  set -x
  oc patch installplan "$1" --patch '{"spec": {"approved": true}}' --type merge
  { set +x ; } 2>/dev/null
}

function find_install_plans {
  for csv in {{ join " " $approveCSVs }}; do
    oc get installplan -ogo-template='
      {{ "{{-" }} range $ip := .items {{ "}}" }}
        {{ "{{-" }} range .spec.clusterServiceVersionNames {{ "}}" }}
          {{ "{{-" }} if eq . "'"$csv"'" {{ "}}" }}
            {{ "{{-" }} $ip.metadata.name }}{{ "{{break}}" }}
          {{ "{{-" }} end {{ "}}" }}
        {{ "{{-" }} end {{ "}}" }}
      {{ "{{-" }} end {{ "}}" }}' 2>/dev/null
    echo
  done
}

echo -n 'Waiting for InstallPlan.'
while true; do
  install_plans=( $(find_install_plans) )
  if [ "${#install_plans[@]}" -eq 0 ]; then
    echo -n '.'
    sleep 1
  else
    echo
    for install_plan in "${install_plans[@]}"; do
      approve_install_plan "$install_plan"
    done
    break
  fi
done
