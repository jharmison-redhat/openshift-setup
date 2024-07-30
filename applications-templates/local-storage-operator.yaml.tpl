---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: local-storage-operator
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  annotations:
    argocd.argoproj.io/sync-wave: "0"
spec:
  destination:
    name: in-cluster
    namespace: openshift-local-storage
  project: default
  source:
    path: charts/local-storage-operator
    repoURL: ${ARGO_GIT_URL}
    targetRevision: ${ARGO_GIT_REVISION}
    helm:
      valueFiles: []
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
    managedNamespaceMetadata:
      labels:
        argocd.argoproj.io/managed-by: openshift-gitops
        openshift.io/cluster-monitoring: "true"
