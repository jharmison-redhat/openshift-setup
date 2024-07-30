---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nvidia-gpu-enablement
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  annotations:
    argocd.argoproj.io/sync-wave: "2"
spec:
  destination:
    name: in-cluster
    namespace: default
  project: default
  source:
    path: charts/nvidia-gpu-enablement
    repoURL: ${ARGO_GIT_URL}
    targetRevision: ${ARGO_GIT_REVISION}
    helm:
      valueFiles: []
  syncPolicy:
    automated:
      prune: true
      selfHeal: true