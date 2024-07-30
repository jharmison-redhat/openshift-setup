---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: registry-local-storage
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  annotations:
    argocd.argoproj.io/sync-wave: "2"
spec:
  destination:
    name: in-cluster
    namespace: openshift-image-registry
  project: default
  source:
    path: charts/registry-local-storage
    repoURL: ${ARGO_GIT_URL}
    targetRevision: ${ARGO_GIT_REVISION}
    helm:
      valueFiles: []
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
