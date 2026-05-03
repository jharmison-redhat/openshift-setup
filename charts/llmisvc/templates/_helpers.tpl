{{/*
Expand the name of the chart.
*/}}
{{- define "llminferenceservice.name" -}}
{{- default .Chart.Name .Values.model.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "llminferenceservice.fullname" -}}
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
{{- define "llminferenceservice.displayname" -}}
{{- default (.Values.model.name | replace "-" " " | title) .Values.displaynameOverride }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "llminferenceservice.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "llminferenceservice.labels" -}}
helm.sh/chart: {{ include "llminferenceservice.chart" . }}
app.kubernetes.io/name: {{ include "llminferenceservice.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Image Reference - sha256 or tag
*/}}
{{- define "llminferenceservice.image.tag" -}}
{{- if .Values.image.manifestHash -}}
@sha256:{{ .Values.image.manifestHash }}
{{- else -}}
:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end }}
{{- end }}
{{- define "llminferenceservice.image" -}}
{{ .Values.image.registry }}/{{ .Values.image.repository }}{{ include "llminferenceservice.image.tag" . }}
{{- end }}

{{/*
Convenience function to template dockerconfigjson
*/}}
{{- define "llminferenceservice.dockerconfigjson" -}}
{{- if .pullSecret.authString -}}
{ "auths": { {{ quote .registry }}: { "auth": {{ quote .pullSecret.authString }} } } }
{{- else -}}
{ "auths": { {{ quote .registry }}: { "auth": {{ quote ((printf "%s:%s" .pullSecret.username .pullSecret.password) | b64enc) }} } } }
{{- end }}
{{- end }}
