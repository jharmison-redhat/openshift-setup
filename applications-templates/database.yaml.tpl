# NOTE: Please update this application's name and namespace - it is intended only to scaffold.
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: database
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  annotations:
    argocd.argoproj.io/sync-wave: "4"
spec:
  destination:
    name: in-cluster
    namespace: default
  project: default
  source:
    path: charts/databse
    repoURL: ${ARGO_GIT_URL}
    targetRevision: ${ARGO_GIT_REVISION}
    helm:
      valueFiles: []
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
