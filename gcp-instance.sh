#!/bin/bash
if [[ -f include/param.sh ]]; then
    . include/param.sh
else
    DISK_TYPE=""
    MACHINE_TYPE="n2d-hichgpu-16"
fi

if [ -n "$DISK_TYPE" ]; then
    gcloud compute disks create llama-data-1 --description="Data disk" --type=$DISK_TYPE --size=30 --labels=protected=false,mode=rw,fs=ext4,boot=false
    GCLOUD_OPTS="--disk=auto-delete=yes,boot=no,name=llama-data-1,mode=rw"
    #printf "Provisioning $MACHINE_TYPE instance with $DISK_TYPE disk...\n"
#else
    #printf "Provisioning $MACHINE_TYPE instance...\n"
fi

mapfile -t OUTPUT < <(gcloud beta compute instances create llama-cpp-1 \
    --machine-type=${MACHINE_TYPE} \
    --network-interface=network-tier=STANDARD,subnet=default \
    --metadata-from-file=startup-script=include/startup.sh \
    --no-restart-on-failure \
    --maintenance-policy=TERMINATE \
    --provisioning-model=SPOT \
    --instance-termination-action=DELETE \
    --max-run-duration=4h \
    --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
    --disk=auto-delete=no,boot=yes,name=test-1,mode=rw \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=ec-src=vm_add-gcloud \
    --reservation-affinity=any ${GCLOUD_OPTS})

if [[ -f scripts/autoconnect.sh ]]; then
   . scripts/autoconnect.sh
else
   printf "${OUTPUT[0]}\n"
   for i in "${OUTPUT[@]:1}"; do
       printf "${i}\n"
   done
fi
