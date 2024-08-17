{{- define "oauth.htpasswd" -}}
{{- if .htpasswd -}}
{{ .htpasswd }}
{{- else -}}
{{- range $user, $password := . -}}
{{ htpasswd $user $password }}
{{ end -}}
{{- end -}}
{{- end -}}
