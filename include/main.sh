#!/bin/bash

METADATA_ATTRS_URL="http://metadata.google.internal/computeMetadata/v1/instance/attributes"

curl "${METADATA_ATTRS_URL}/format-disk-script" \
  -H "Metadata-Flavor: Google" > /tmp/format-disk.sh

curl "${METADATA_ATTRS_URL}/mount-partitions-script" \
  -H "Metadata-Flavor: Google" > /tmp/mount-partitions.sh

source /tmp/format-disk.sh
source /tmp/mount-partitions.sh
