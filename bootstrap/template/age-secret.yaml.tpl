apiVersion: v1
kind: Secret
metadata:
  name: helm-secrets-private-keys
  namespace: openshift-gitops
type: Opaque
data:
  argo.txt: ${BASE64_ARGO_AGE_SECRET}
