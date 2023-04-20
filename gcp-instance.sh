#!/bin/bash
if [[ -f include/param.sh ]]; then
    . include/param.sh
else
    DISK_TYPE=""
    DISK_SIZE=30
    MACHINE_TYPE="n2d-hichgpu-16"
fi

MACHINE_TYPE=${MACHINE_TYPE:-"n2d-highcpu-16"}
case $DISK_TYPE in
    standard|s|std|"") DISK_TYPE="pd-standard";;
    balanced|b|bal) DISK_TYPE="pd-balanced";;
    none) DISK_TYPE="";;
    *) usage_fatal "invalid disk type: '$DISK_TYPE'";;
esac

case $GPU_TYPE in
    t4|"") GPU_TYPE="nvidia-tesla-t4";;
    k80) GPU_TYPE="nvidia-tesla-k80";;
    none) GPU_TYPE="";;
    *) usage_fatal "invalid GPU type: '$GPU_TYPE'";;
esac

if [ -n "$GPU_TYPE" ]; then
    GCLOUD_OPTS="${GCLOUD_OPTS} --accelerator=count=1,type=$GPU_TYPE"
    if [[ ! "$MACHINE_TYPE" =~ "^n1-" ]]; then
        printf "$MACHINE_TYPE not compatible with GPU acceleration.\n"
        printf "Selecting 'n1-highmem-4' as instance type.\n"
        MACHINE_TYPE="n1-highmem-4";
    fi
    # GPU instances need additional storage
    DISK_TYPE="pd-balanced"
fi

DISK_NAME=data-$(head -c2 </dev/urandom|xxd -p)
if [ -n "$DISK_TYPE" ]; then
    gcloud compute disks create $DISK_NAME --description="Data disk" --type=$DISK_TYPE --size=$DISK_SIZE --labels=protected=false,mode=rw,fs=ext4,boot=false
    GCLOUD_OPTS="${GCLOUD_OPTS} --disk=auto-delete=yes,boot=no,name=${DISK_NAME},mode=rw"
fi

# e2-micro is part of GCP free tier
if [ "$MACHINE_TYPE" != "e2-micro" ]; then
    GCLOUD_OPTS="${GCLOUD_OPTS} --maintenance-policy=TERMINATE \
        --provisioning-model=SPOT \
        --instance-termination-action=DELETE \
        --max-run-duration=4h"
fi

mapfile -t OUTPUT < <(gcloud beta compute instances create llama-cpp-$(head -c2 </dev/urandom|xxd -p) \
    --machine-type=${MACHINE_TYPE} \
    --network-interface=network-tier=STANDARD,subnet=default \
    --metadata-from-file=startup-script=include/startup.sh \
    --no-restart-on-failure \
    --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
    --disk=auto-delete=no,boot=yes,name=test-1,mode=rw \
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
