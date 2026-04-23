{{/*
Expand the name of the chart.
*/}}
{{- define "postgres-cluster.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "postgres-cluster.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
     Create chart name and version as used by the chart label.
   */}}
{{- define "postgres-cluster.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
     Common labels
   */}}
{{- define "postgres-cluster.labels" -}}
helm.sh/chart: {{ include "postgres-cluster.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "postgres-cluster.certificate.secret.fullname" -}}
{{- include "postgres-cluster.fullname" . }}-certificate
{{- end }}

{{- define "postgres-cluster.certificate.dnsNames" -}}
{{- $ns := .Values.namespace | default .Release.Namespace }}
{{- range $svc := .Values.services }}
{{- end }}
{{- end }}

{{- define "postgres-cluster.disabledServices" -}}
{{- $diff := list -}}
{{- $services := .Values.services }}
{{- range $item := list "rw" "ro" "r" -}}
  {{- if not (has $item $services) -}}
    {{- $diff = append $diff $item -}}
  {{- end -}}
{{- end }}
{{- $diff | toJson }}
{{- end }}
