---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: acm-infraenv
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  annotations:
    argocd.argoproj.io/sync-wave: "3"
spec:
  destination:
    name: in-cluster
    namespace: open-cluster-management
  project: default
  source:
    path: charts/acm-infraenv
    repoURL: ${ARGO_GIT_URL}
    targetRevision: ${ARGO_GIT_REVISION}
    helm:
      valueFiles: []
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - RespectIgnoreDifferences=true
