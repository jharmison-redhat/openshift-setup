---
apiVersion: v1
kind: Secret
metadata:
  name: git-repo
  namespace: openshift-gitops
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
data:
  type: Z2l0
  url: ${BASE64_ARGO_GIT_URL}
  sshPrivateKey: ${BASE64_ARGO_SSH_SECRET}
  enableLfs: dHJ1ZQ==
