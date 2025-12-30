#!/bin/bash

# Procesar argumentos
FORCE_DELETE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE_DELETE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [-f|--force]"
            echo "  -f, --force    Delete protected data disks (protected=true AND boot=false)"
            exit 1
            ;;
    esac
done

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

# Manejo de discos protegidos según el flag --force
if [ "$FORCE_DELETE" = true ]; then
    mapfile -t PROTECTED_DATA_DISKS < <(gcloud compute disks list --format="csv[no-heading](name,size_gb)" --filter="labels.protected=true AND labels.boot=false")
    if [[ -n $PROTECTED_DATA_DISKS ]]; then
        for i in "${PROTECTED_DATA_DISKS[@]}"; do
            NAME=${i%,*}
            SIZE=${i#*,}
            echo "Force deleting protected data disk ${NAME} (${SIZE} GB)..."
            gcloud -q compute disks delete ${NAME}
        done
    else
        echo "No protected data disks found"
    fi

    mapfile -t BOOT_DISKS < <(gcloud compute disks list --format="csv[no-heading](name,size_gb)" --filter="labels.boot=true")
    if [[ -n $BOOT_DISKS ]]; then
        for i in "${BOOT_DISKS[@]}"; do
            NAME=${i%,*}
            SIZE=${i#*,}
            echo "Not deleting boot disk ${NAME} (${SIZE} GB)"
        done
    else
        echo "No boot disks found"
    fi
else
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
fi
