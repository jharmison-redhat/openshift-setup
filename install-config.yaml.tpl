---
apiVersion: v1
metadata:
  creationTimestamp: null
  name: ${CLUSTER_NAME}
baseDomain: ${BASE_DOMAIN}
compute:
  - architecture: amd64
    hyperthreading: Enabled
    name: worker
    platform:
      aws:
        type: ${WORKER_TYPE}
    replicas: ${WORKER_COUNT}
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  platform:
    aws:
      type: ${CONTROL_PLANE_TYPE}
  replicas: ${CONTROL_PLANE_COUNT}
networking:
  clusterNetwork:
    - cidr: 10.128.0.0/14
      hostPrefix: 23
  machineNetwork:
    - cidr: 10.0.0.0/16
  networkType: OVNKubernetes
  serviceNetwork:
    - 172.30.0.0/16
platform:
  aws:
    region: ${AWS_REGION}
publish: External
additionalTrustBundlePolicy: Proxyonly
pullSecret: ${PULL_SECRET}
sshKey: ${SSH_KEY}
