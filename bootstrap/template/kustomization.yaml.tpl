---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

commonLabels:
  cluster: ${CLUSTER_URL}

resources:
  - ../../../bootstrap
  - age-secret.yaml
  - ssh-keys.yaml
  - app-of-apps.yaml
