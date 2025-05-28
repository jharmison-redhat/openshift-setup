{{- define "oauth.htpasswd" -}}
{{- if .htpasswd -}}
{{ .htpasswd }}
{{- else -}}
{{- range $user, $password := . -}}
{{- if $password -}}
{{ htpasswd $user $password }}
{{ end -}}
{{- end -}}
{{- end -}}
{{- end -}}
