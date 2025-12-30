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
mapfile -t UNPROTECTED_DISKS < <(gcloud compute disks list --format="csv[no-heading](name,size_gb)" --filter="labels.protected=false AND labels.boot=false")
if [[ -n $UNPROTECTED_DISKS ]]; then
    for i in "${UNPROTECTED_DISKS[@]}"; do
        NAME=${i%,*}
        SIZE=${i#*,}
        echo "Deleting unprotected data disk ${NAME} (${SIZE} GB)..."
        gcloud -q compute disks delete ${NAME}
    done
else
    echo "No unprotected data disks found"
fi

mapfile -t DISKS < <(gcloud compute disks list --format="csv[no-heading](name,size_gb)" --filter="labels.protected=true OR labels.boot=true")
if [[ -n $DISKS ]]; then
    for i in "${DISKS[@]}"; do
        NAME=${i%,*}
        SIZE=${i#*,}
        echo "Not deleting disk ${NAME} (${SIZE} GB)"
    done
else
    echo "No boot/protected disks found"
fi
