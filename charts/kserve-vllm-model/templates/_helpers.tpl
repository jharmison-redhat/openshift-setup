{{/*
Expand the name of the chart.
*/}}
{{- define "kserve-vllm-model.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kserve-vllm-model.fullname" -}}
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
{{- define "kserve-vllm-model.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kserve-vllm-model.labels" -}}
helm.sh/chart: {{ include "kserve-vllm-model.chart" . }}
app.kubernetes.io/name: {{ include "kserve-vllm-model.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kserve-vllm-model.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "kserve-vllm-model.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image Reference - sha256 or tag
*/}}
{{- define "kserve-vllm-model.image.tag" -}}
{{- if .Values.image.manifestHash -}}
@sha256:{{ .Values.image.manifestHash }}
{{- else -}}
:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end }}
{{- end }}
{{- define "kserve-vllm-model.image" -}}
{{ .Values.image.registry }}/{{ .Values.image.repository }}{{ include "kserve-vllm-model.image.tag" . }}
{{- end }}

