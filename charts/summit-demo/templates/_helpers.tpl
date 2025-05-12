{{- define "summit-demo.model-providers" -}}
{{- range $model := .Values.models }}
{{- "" }}- provider_id: {{ required "A model short name, from the vLLM API, is required" $model.model }}
  provider_type: {{ $model.providerType | default "remote::vllm" }}
  config:
    url: {{ tpl (required "A URL is required for each model" $model.url) $ }}
    max_tokens: {{ $model.maxTokens | default 128000 }}
    api_token: {{ $model.token | default "fake" }}
    tls_verify: {{ $model.tlsVerify | default "true" }}
{{- end }}
{{- end }}

{{- define "summit-demo.models" -}}
{{- range $model := .Values.models }}
{{- "" }}- metadata: {}
  model_id: {{ $model.model }}
  provider_id: {{ $model.model }}
  model_type: llm
{{- end }}
{{- end }}
