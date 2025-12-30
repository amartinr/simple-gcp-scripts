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
    echo "No compute instances found"
fi

printf "=== COMPUTE DISKS =================\n"
mapfile -t UNPROTECTED_DISKS < <(gcloud compute disks list --format="csv[no-heading](name,size_gb)" --filter=labels.protected=false)
if [[ -n $UNPROTECTED_DISKS ]]; then
    for i in "${UNPROTECTED_DISKS[@]}"; do
        NAME=${i%,*}
        SIZE=${i#*,}
        echo "Deleting unprotected disk ${NAME} (${SIZE} GB)..."
        gcloud -q compute disks delete ${NAME}
    done
else
    echo "No unprotected disks found"
fi

mapfile -t DISKS < <(gcloud compute disks list --format="csv[no-heading](name,size_gb)" --filter=labels.protected=true)
if [[ -n $DISKS ]]; then
    for i in "${DISKS[@]}"; do
        NAME=${i%,*}
        SIZE=${i#*,}
        echo "Not deleting protected disk ${NAME} (${SIZE} GB)"
    done
else
    echo "No protected disks found"
fi
