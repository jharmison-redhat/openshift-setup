---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: summit-demo
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  annotations:
    argocd.argoproj.io/sync-wave: "6"
spec:
  destination:
    name: in-cluster
    namespace: llama-serve
  project: default
  source:
    path: charts/summit-demo
    repoURL: ${ARGO_GIT_URL}
    targetRevision: ${ARGO_GIT_REVISION}
    helm:
      valueFiles: []
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    retry:
      limit: 10
      backoff:
        duration: 10s
        factor: 3
        maxDuration: 60m
    syncOptions:
      - CreateNamespace=true
    managedNamespaceMetadata:
      labels:
        argocd.argoproj.io/managed-by: openshift-gitops
