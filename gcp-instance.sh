#!/bin/bash
if [[ -f include/param.sh ]]; then
    . include/param.sh
else
    DATA_DISK_TYPE="none"
    DATA_DATA_DISK_SIZE=30
    MACHINE_TYPE="e2-micro"
fi

SUFFIX=$(head -c2 </dev/urandom | xxd -p)

MACHINE_TYPE=${MACHINE_TYPE:-"e2-micro"}
case $DATA_DISK_TYPE in
    standard|s|std|"") DATA_DISK_TYPE="pd-standard";;
    balanced|b|bal) DATA_DISK_TYPE="pd-balanced";;
    ssd) DATA_DISK_TYPE="pd-ssd";;
    none) DATA_DISK_TYPE="";;
    *) usage_fatal "invalid disk type: '$DATA_DISK_TYPE'";;
esac

case $GPU_TYPE in
    t4|"") GPU_TYPE="nvidia-tesla-t4";;
    p4) GPU_TYPE="nvidia-tesla-p4";;
    k80) GPU_TYPE="nvidia-tesla-k80";;
    none) GPU_TYPE="";;
    *) usage_fatal "invalid GPU type: '$GPU_TYPE'";;
esac

if [ -n "$GPU_TYPE" ]; then
    GCLOUD_OPTS="${GCLOUD_OPTS} \
        --accelerator=count=1,type=$GPU_TYPE"
    #if [[ ! "$MACHINE_TYPE" =~ "^n1-" ]]; then
    #    printf "$MACHINE_TYPE not compatible with GPU acceleration.\n"
    #    printf "Selecting 'n1-highmem-4' as instance type.\n"
    #    MACHINE_TYPE="n1-highmem-4";
    #fi
    # GPU instances need additional storage
    #DATA_DISK_TYPE="pd-balanced"
fi

if [ -n "$DATA_DISK_TYPE" ]; then
    DATA_DISK_NAME=llama-data-${SUFFIX}
    if [ "$DISK_PERSISTENT" = "false" ]; then
        AUTO_DELETE="yes"
        PROTECTED="false"
    else
        AUTO_DELETE="no"
        PROTECTED="true"
    fi
    gcloud compute disks create $DATA_DISK_NAME \
        --description="Data disk" \
        --type=$DATA_DISK_TYPE \
        --size=$DATA_DISK_SIZE \
        --labels=protected=${PROTECTED},mode=rw,fs=ext4,boot=false \
        --quiet
    GCLOUD_OPTS="${GCLOUD_OPTS} \
        --disk=auto-delete=${AUTO_DELETE},boot=no,name=${DATA_DISK_NAME},mode=rw"
fi

# e2-micro is part of GCP free tier
if [ "$MACHINE_TYPE" != "e2-micro" ]; then
    GCLOUD_OPTS="${GCLOUD_OPTS} --maintenance-policy=TERMINATE \
        --provisioning-model=SPOT \
        --instance-termination-action=DELETE \
        --max-run-duration=4h"
fi

mapfile -t OUTPUT < <(gcloud beta compute instances create llama-${SUFFIX} \
    --machine-type=${MACHINE_TYPE} \
    --network-interface=network-tier=STANDARD,subnet=default \
    --metadata-from-file=startup-script=include/startup.sh \
    --no-restart-on-failure \
    --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
    --disk=auto-delete=no,boot=yes,name=llama-boot,mode=rw \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=ec-src=vm_add-gcloud \
    --reservation-affinity=any ${GCLOUD_OPTS})

if [[ -f include/autoconnect.sh ]]; then
   . include/autoconnect.sh
else
   printf "${OUTPUT[0]}\n"
   for i in "${OUTPUT[@]:1}"; do
       printf "${i}\n"
   done
fi
