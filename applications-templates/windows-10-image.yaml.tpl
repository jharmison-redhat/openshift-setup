---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: windows-10-image
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  annotations:
    argocd.argoproj.io/sync-wave: "4"
spec:
  destination:
    name: in-cluster
    namespace: openshift-cnv
  project: default
  source:
    path: charts/windows-10-image
    repoURL: ${ARGO_GIT_URL}
    targetRevision: ${ARGO_GIT_REVISION}
    helm:
      valueFiles: []
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
