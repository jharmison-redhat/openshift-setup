{{- define "keycloak.hostname" -}}
{{- if .hostname -}}
{{ tpl .hostname . }}
{{- else -}}
{{ .name }}.apps.{{ .global.cluster.name }}.{{ .global.cluster.baseDomain }}
{{- end -}}
{{- end -}}
