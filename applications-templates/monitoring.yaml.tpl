---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: monitoring
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  annotations:
    argocd.argoproj.io/sync-wave: "1"
spec:
  destination:
    name: in-cluster
    namespace: openshift-monitoring
  project: default
  source:
    path: charts/monitoring
    repoURL: ${ARGO_GIT_URL}
    targetRevision: ${ARGO_GIT_REVISION}
    helm:
      valueFiles: []
  syncPolicy:
    automated:
      prune: true
      selfHeal: true