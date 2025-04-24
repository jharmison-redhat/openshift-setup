---
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: user-namespaces
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  annotations:
    argocd.argoproj.io/sync-wave: "3"
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
    - matrix:
        generators:
          - git:
              repoURL: ${ARGO_GIT_URL}
              revision: ${ARGO_GIT_REVISION}
              files:
                - path: clusters/${CLUSTER_URL}/values/user-namespaces/values.yaml
          - list:
              elementsYaml: |-
                {{- range $name := .users }}
                - name: {{ $name }}
                {{- end }}
  template:
    metadata:
      name: "user-namespace-{{ .name }}"
    spec:
      destination:
        name: in-cluster
        namespace: default
      project: default
      source:
        path: charts/namespace
        repoURL: ${ARGO_GIT_URL}
        targetRevision: ${ARGO_GIT_REVISION}
        helm:
          valuesObject:
            name: "{{ .name }}"
            namespaceAdmins:
              - "{{ .name }}"
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
