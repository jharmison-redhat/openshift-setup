---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: aws-nvidia-gpu-machinesets
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  annotations:
    argocd.argoproj.io/sync-wave: "2"
spec:
  destination:
    name: in-cluster
    namespace: openshift-machine-api
  project: default
  source:
    path: charts/aws-nvidia-gpu-machinesets
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
    syncOptions:
      - RespectIgnoreDifferences=true
  ignoreDifferences:
    - group: machine.openshift.io
      kind: MachineSet
      jsonPointers:
        - /spec/replicas
