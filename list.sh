#!/bin/bash

# compute instances
#mapfile -t OUTPUT < <(gcloud compute instances list --format="csv[separator=',',no-heading](name,networkInterfaces[0].accessConfigs[0].natIP,status,machineType,scheduling.provisioningModel,creationTimestamp)")
mapfile -t OUTPUT < <(gcloud compute instances list --format="table(name,networkInterfaces[0].accessConfigs[0].natIP,status,machineType,scheduling.provisioningModel,creationTimestamp)")
HEADER=${OUTPUT[0]//CREATION_TIMESTAMP/LIFETIME (S)}

printf "=== COMPUTE INSTANCES =============\n"
if [[ -n "${OUTPUT[@]:1}" ]]; then
    for i in "${OUTPUT[@]:1}"; do 
        read NAME NATIP STATUS MACHINETYPE \
             PROVISIONINGMODEL CREATION_TIMESTAMP <<< $i
        LIFETIME=$(($(date +%s) - $(date -d $CREATION_TIMESTAMP +%s)))
        LIFETIME_M=$(($LIFETIME / 60))
        LIFETIME_H=$(($LIFETIME / 3600))
    done
    printf "$HEADER\n"
    printf "${i//????-??-??T??:??:??*/$LIFETIME}\n"
else
    printf "No compute instances found.\n"
fi

# compute disks
mapfile -t OUTPUT < <(gcloud compute disks list)
HEADER=${OUTPUT[0]}

printf "=== COMPUTE DISKS =================\n"
if [[ -n "${OUTPUT[@]:1}" ]]; then
    for i in "${OUTPUT[@]:1}"; do 
        read NAME LOCATION LOCATION_SCOPE \
             SIZE_GB TYPE STATUS <<< $i
    done
    printf "$HEADER\n"
    for i in "${OUTPUT[@]:1}"; do 
        printf "${i}\n"
    done
else
    printf "No compute disks found.\n"
fi
