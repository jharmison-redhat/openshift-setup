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
# maas-api (RHOAI 3.5.0+) reads maas-db-config from its own namespace, which is
# also where the postgres cluster lives
oc create secret generic maas-db-config -n {{ $db.namespace }} --from-literal=DB_CONNECTION_URL="$uri" --dry-run=client -oyaml | oc apply -f-
