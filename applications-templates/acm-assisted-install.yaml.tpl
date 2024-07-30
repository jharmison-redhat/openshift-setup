---
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: acm-assisted-install
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  annotations:
    argocd.argoproj.io/sync-wave: "4"
spec:
  generators:
    - git:
        repoURL: ${ARGO_GIT_URL}
        revision: ${ARGO_GIT_REVISION}
        files:
          - path: "clusters/${CLUSTER_URL}/provision/**/provision.yaml"
  syncPolicy:
    preserveResourcesOnDeletion: true
  template:
    metadata:
      name: "provision-{{ cluster.name }}"
    spec:
      destination:
        name: in-cluster
        namespace: "{{ cluster.name }}"
      project: default
      source:
        path: charts/acm-assisted-install
        repoURL: ${ARGO_GIT_URL}
        targetRevision: ${ARGO_GIT_REVISION}
        helm:
          valueFiles:
            - "/clusters/${CLUSTER_URL}/provision/{{ cluster.name }}/provision.yaml"
      ignoreDifferences:
        - group: cluster.open-cluster-management.io
          kind: ManagedCluster
          jsonPointers:
            - /metadata/labels
        - group: extensions.hive.openshift.io
          kind: AgentClusterInstall
          jsonPointers:
            - /spec/imageSetRef/name
      syncPolicy:
        automated:
          prune: false
          selfHeal: true
        syncOptions:
          - RespectIgnoreDifferences=true
          - CreateNamespace=true
        managedNamespaceMetadata:
          labels:
            argocd.argoproj.io/managed-by: openshift-gitops
