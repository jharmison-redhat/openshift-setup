#!/bin/sh

function target_filesystem {
    oc get filesystem.efs.services.k8s.aws {{ .Values.storageClass.dynamicFromAck.filesystem.name }} "${@}"
}

echo -n "Waiting for filesystem to be available"
while [ $(target_filesystem -ojsonpath='{.status.lifeCycleState}') != "available" ]; do
    sleep 1
    echo -n .
done
echo

echo "Creating StorageClass"

fs_id=$(target_filesystem -ojsonpath='{.status.fileSystemID}')
cat << EOF | oc apply -f-
$(cat /mnt/create-sc-without-id.yaml)
  fileSystemId: ${fs_id}
EOF
