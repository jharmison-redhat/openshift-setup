{{- define "aws-nvidia-gpu-machinesets.az" -}}
{{- if .Values.aws.az -}}
{{ .Values.aws.az }}
{{- else -}}
{{ last .Values.aws.azs }}
{{- end -}}
{{- end -}}
