---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: aws-efs-csi-driver-operator
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  annotations:
    argocd.argoproj.io/sync-wave: "2"
spec:
  destination:
    name: in-cluster
    namespace: openshift-cluster-csi-drivers
  project: default
  source:
    path: charts/aws-efs-csi-driver-operator
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
        maxDuration: 30m
