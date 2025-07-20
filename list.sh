#!/bin/bash
TZ=America/Los_Angeles
OUTPUT=$(gcloud compute instances list --format=json)
if [[ $(echo "$OUTPUT" | jq 'length') -gt 0 ]]; then
    echo "$OUTPUT" | jq -r --arg now $(TZ=America/Los_Angeles date +"%Y-%m-%dT%H:%M:%S%z") '.[] |
    {
        name,
        kind,
        IP: .networkInterfaces[0].accessConfigs[0].natIP,
        status,
        zone: (.zone | split("/") | last),
        type: (.machineType | split("/") | last),
        accelerator: (if .guestAccelerators then (.guestAccelerators[0].acceleratorType | split("/") | last) else null end),
        provision: .scheduling.provisioningModel,
        lifetime: (($now | sub("(?<time>.*)\\.[\\d]{3}(?<tz>.*)"; "\(.time)\(.tz)") | strptime("%Y-%m-%dT%H:%M:%S%z") | mktime) - (.creationTimestamp | sub("(?<time>.*)\\.[\\d]{3}(?<tz>.*)"; "\(.time)\(.tz)") | strptime("%Y-%m-%dT%H:%M:%S%z") | mktime)) | tostring
    }'
fi

OUTPUT=$(gcloud compute disks list --format=json)
if [[ $(echo "$OUTPUT" | jq 'length') -gt 0 ]]; then echo "$OUTPUT" | jq -r '.[] |
        {
            name,
            kind,
            zone: (.zone | split("/") | last),
            type: (.type | split("/") | last),
            sizeGb,
            status
        }'
else
    printf "No compute disks found.\n"
fi
