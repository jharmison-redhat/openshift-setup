#!/bin/bash
{{- $db := index .Values "postgres-cluster" }}
{{- $name := default .Chart.Name $db.nameOverride | trunc 63 | trimSuffix "-" }}
{{- $fullname := printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}

{{- if $db.fullnameOverride }}
{{- $fullname = $db.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else if contains $name .Release.Name }}
{{- $fullname = $.Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

uri=$(oc get secret {{ $fullname }}-app -ojsonpath='{.data.uri}' | base64 -d)
oc create secret generic maas-db-config -n redhat-ods-applications --from-literal=DB_CONNECTION_URL="$uri" --dry-run=client -oyaml | oc apply -f-
# maas-api (redhat-ai-gateway-infra, RHOAI 3.5.0+) reads maas-db-config from its own namespace
# ponytail: naive retry-free; Job backoffLimit re-runs the script if redhat-ai-gateway-infra isn't up yet
oc create secret generic maas-db-config -n redhat-ai-gateway-infra --from-literal=DB_CONNECTION_URL="$uri" --dry-run=client -oyaml | oc apply -f-
