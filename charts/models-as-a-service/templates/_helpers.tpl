{{/*
Expand the name of the chart.
*/}}
{{- define "models-as-a-service.name" -}}
{{- default .Chart.Name .Values.model.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "models-as-a-service.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.model.name }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create a display name, for use in the OpenShift and OpenShift AI consoles
*/}}
{{- define "models-as-a-service.displayname" -}}
{{- default (.Values.model.name | replace "-" " " | title) .Values.displaynameOverride }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "models-as-a-service.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "models-as-a-service.labels" -}}
helm.sh/chart: {{ include "models-as-a-service.chart" . }}
app.kubernetes.io/name: {{ include "models-as-a-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Image Reference - sha256 or tag
*/}}
{{- define "models-as-a-service.image.tag" -}}
{{- if .Values.image.manifestHash -}}
@sha256:{{ .Values.image.manifestHash }}
{{- else -}}
:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end }}
{{- end }}
{{- define "models-as-a-service.image" -}}
{{ .Values.image.registry }}/{{ .Values.image.repository }}{{ include "models-as-a-service.image.tag" . }}
{{- end }}

{{/*
Convenience function to template dockerconfigjson
*/}}
{{- define "models-as-a-service.dockerconfigjson" -}}
{{- if .pullSecret.authString -}}
{ "auths": { {{ quote .registry }}: { "auth": {{ quote .pullSecret.authString }} } } }
{{- else -}}
{ "auths": { {{ quote .registry }}: { "auth": {{ quote ((printf "%s:%s" .pullSecret.username .pullSecret.password) | b64enc) }} } } }
{{- end }}
{{- end }}
