---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: openshift-pipelines
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  annotations:
    argocd.argoproj.io/sync-wave: "1"
spec:
  destination:
    name: in-cluster
    namespace: openshift-operators
  project: default
  source:
    path: charts/openshift-pipelines
    repoURL: ${ARGO_GIT_URL}
    targetRevision: ${ARGO_GIT_REVISION}
    helm:
      valueFiles: []
  syncPolicy:
    automated:
      prune: true
      selfHeal: true