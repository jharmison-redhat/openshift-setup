---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: lvm-storage
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  annotations:
    argocd.argoproj.io/sync-wave: "0"
spec:
  destination:
    name: in-cluster
    namespace: openshift-storage
  project: default
  source:
    path: charts/lvm-storage
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
        pod-security.kubernetes.io/enforce: privileged
        pod-security.kubernetes.io/audit: privileged
        pod-security.kubernetes.io/warn: privileged
