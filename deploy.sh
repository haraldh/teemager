#!/usr/bin/env bash

set -ex

NO=${NO:-1}

nix build -L .#verity

gsutil cp result/test_tdx_1.vmdk gs://tdx_vms/

gcloud migration vms image-imports create \
         --location=us-central1 \
         --target-project=tdx-pilot \
         --project=tdx-pilot \
         --skip-os-adaptation \
         --source-file=gs://tdx_vms/test_tdx_1.vmdk \
         tdx-img-pre-"${NO}"

gcloud compute instances stop tdx-pilot --zone us-central1-c --project tdx-pilot || :
gcloud compute instances delete tdx-pilot --zone us-central1-c --project tdx-pilot || :

while gcloud migration vms image-imports list --location=us-central1 --project=tdx-pilot | grep -F RUNNING; do
    sleep 1
done

gcloud compute images create \
         --project tdx-pilot \
         --guest-os-features=UEFI_COMPATIBLE,TDX_CAPABLE,GVNIC,VIRTIO_SCSI_MULTIQUEUE \
         --storage-location=us-central1 \
         --source-image=tdx-img-pre-"${NO}" \
         tdx-img-f-"${NO}"

gcloud compute instances create tdx-pilot \
         --machine-type c3-standard-4 --zone us-central1-c \
         --confidential-compute-type=TDX \
         --maintenance-policy=TERMINATE \
         --image-project=tdx-pilot \
         --project tdx-pilot \
         --image tdx-img-f-"${NO}"
