{{- define "azure-nvidia-gpu-machinesets.image" -}}
{{- if .Values.azure.imageResourceId -}}
offer: ""
publisher: ""
resourceID: {{ .Values.azure.imageResourceId }}
sku: ""
version: ""
{{- else -}}
offer: {{ .Values.azure.offer }}
publisher: {{ .Values.azure.publisher }}
resourceID: ""
sku: {{ .Values.azure.sku }}
version: {{ .Values.azure.version }}
type: {{ .Values.azure.type }}
{{- end -}}
{{- end -}}

{{- define "azure-nvidia-gpu-machinesets.rg" -}}
{{- if .Values.azure.resourceGroup -}}
{{ .Values.azure.resourceGroup }}
{{- else -}}
{{ .Values.cluster.infraID }}-rg
{{- end -}}
{{- end -}}

{{- define "azure-nvidia-gpu-machinesets.network-rg" -}}
{{- if .Values.azure.networkResourceGroup -}}
{{ .Values.azure.networkResourceGroup }}
{{- else -}}
{{ include "azure-nvidia-gpu-machinesets.rg" . }}
{{- end -}}
{{- end -}}
