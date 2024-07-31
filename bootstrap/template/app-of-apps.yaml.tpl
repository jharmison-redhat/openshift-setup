---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: openshift-gitops
spec:
  destination:
    name: in-cluster
    namespace: openshift-gitops
  project: default
  source:
    path: clusters/${CLUSTER_URL}/applications
    repoURL: ${ARGO_GIT_URL}
    targetRevision: ${ARGO_GIT_REVISION}
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
    - group: argoproj.io
      kind: Application
      jsonPointers:
        - /spec/syncPolicy/automated
