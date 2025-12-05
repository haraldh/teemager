{ pkgs, ... }:

let
  script = pkgs.writeShellApplication {
    name = "create-gcp";

    runtimeInputs = with pkgs; [
      qemu
      google-cloud-sdk-gce
    ];

    text = ''
      # Configuration via environment variables (required except IMAGE_NAME)
      GCP_PROJECT="''${GCP_PROJECT:?Error: GCP_PROJECT is not set}"
      GCP_LOCATION="''${GCP_LOCATION:?Error: GCP_LOCATION is not set}"
      GCP_BUCKET="''${GCP_BUCKET:?Error: GCP_BUCKET is not set}"
      IMAGE_NAME="''${IMAGE_NAME:-nixos-tdx-$(date +%Y%m%d-%H%M%S)}"

      # Check if raw image file is provided
      if [ -z "''${1:-}" ]; then
        echo "Error: Raw image file not provided"
        echo "Usage: create-gcp <raw-image-file>"
        echo ""
        echo "Environment variables (required):"
        echo "  GCP_PROJECT  - Google Cloud project"
        echo "  GCP_LOCATION - Location for image import (e.g., us-central1)"
        echo "  GCP_BUCKET   - GCS bucket for VMDK upload"
        echo ""
        echo "Environment variables (optional):"
        echo "  IMAGE_NAME   - Base name for the image (default: nixos-tdx-<timestamp>)"
        exit 1
      fi

      RAW_IMAGE="$1"

      # Check if the image file exists
      if [ ! -f "$RAW_IMAGE" ]; then
        echo "Error: Raw image file '$RAW_IMAGE' not found"
        exit 1
      fi

      echo "Configuration:"
      echo "  Project:  $GCP_PROJECT"
      echo "  Location: $GCP_LOCATION"
      echo "  Bucket:   $GCP_BUCKET"
      echo "  Image:    $IMAGE_NAME"
      echo ""

      # Create temp directory for VMDK
      TMPDIR=$(mktemp -d)
      cleanup() { rm -rf "$TMPDIR"; }
      trap cleanup EXIT

      VMDK_FILE="$TMPDIR/$IMAGE_NAME.vmdk"

      # Convert raw to VMDK
      echo "Converting raw image to VMDK..."
      qemu-img convert -f raw -O vmdk "$RAW_IMAGE" "$VMDK_FILE"

      # Upload to GCS
      echo "Uploading VMDK to gs://$GCP_BUCKET/..."
      gsutil cp "$VMDK_FILE" "gs://$GCP_BUCKET/$IMAGE_NAME.vmdk"

      # Create image import
      PRE_IMAGE="$IMAGE_NAME-pre"
      echo "Creating image import '$PRE_IMAGE'..."
      gcloud migration vms image-imports create \
        --location="$GCP_LOCATION" \
        --target-project="$GCP_PROJECT" \
        --project="$GCP_PROJECT" \
        --skip-os-adaptation \
        --source-file="gs://$GCP_BUCKET/$IMAGE_NAME.vmdk" \
        "$PRE_IMAGE"

      # Wait for import to complete
      echo "Waiting for image import to complete..."
      while gcloud migration vms image-imports list \
          --location="$GCP_LOCATION" \
          --project="$GCP_PROJECT" 2>/dev/null | grep -qF RUNNING; do
        sleep 5
      done

      # Create final TDX-capable image
      FINAL_IMAGE="$IMAGE_NAME"
      echo "Creating final TDX-capable image '$FINAL_IMAGE'..."
      gcloud compute images create \
        --project="$GCP_PROJECT" \
        --guest-os-features=UEFI_COMPATIBLE,TDX_CAPABLE,GVNIC,VIRTIO_SCSI_MULTIQUEUE \
        --storage-location="$GCP_LOCATION" \
        --source-image="$PRE_IMAGE" \
        "$FINAL_IMAGE"

      echo ""
      echo "Done. Image: $FINAL_IMAGE"
      echo ""
      echo "To create a TDX VM instance:"
      echo "  gcloud compute instances create <instance-name> \\"
      echo "    --machine-type c3-standard-4 --zone $GCP_LOCATION-c \\"
      echo "    --confidential-compute-type=TDX \\"
      echo "    --maintenance-policy=TERMINATE \\"
      echo "    --image-project=$GCP_PROJECT \\"
      echo "    --project=$GCP_PROJECT \\"
      echo "    --image $FINAL_IMAGE"
    '';
  };
in
{
  type = "app";
  program = "${script}/bin/create-gcp";
}
