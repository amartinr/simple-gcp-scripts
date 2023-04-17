#!/bin/bash
mapfile -t INSTANCE < <(gcloud compute instances list --format="csv[no-heading](name,networkInterfaces[0].accessConfigs[0].natIP)")

printf "=== COMPUTE INSTANCES =============\n"
if [[ -n $INSTANCE ]]; then
    for i in "${INSTANCE[@]}"; do
        NAME=${i%,*}
        IP=${i#*,}
        echo "Deleting instance ${NAME} (${IP})..."
        gcloud -q compute instances delete ${NAME}
        ssh-keygen -q -F ${IP} > /dev/null 2>&1 && ssh-keygen -q -R ${IP} > /dev/null 2>&1
    done
else
    echo "No compute instances found."
fi

printf "=== COMPUTE DISKS =================\n"
mapfile -t DISK < <(gcloud compute disks list --format="csv[no-heading](name,size_gb)" --filter=labels.protected=false)
if [[ -n $DISK ]]; then
    for i in "${DISK[@]}"; do
        NAME=${i%,*}
        SIZE=${i#*,}
        echo "Deleting disk ${NAME} (${SIZE} GB)"
        gcloud -q compute disks delete ${NAME}
    done
else
    echo "No compute disks found."
fi
