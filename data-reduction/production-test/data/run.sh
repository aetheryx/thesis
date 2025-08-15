# get devpods
devpod ps --all --region "$DEVPOD_REGION" --json > devpods.json

# get pvcs
kubectl get pvc -n devpod -o json > pvcs.json

# get snapshots
gcloud compute snapshots list \
  --format json \
  --filter "status=READY AND labels.frequency=daily AND creationTimestamp>2025-08-08 AND storageLocations[0]:($GCP_REGIONS)" > snapshots.json
