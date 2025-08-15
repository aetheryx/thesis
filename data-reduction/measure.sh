#!/usr/bin/env -S zsh -d -f -i

local TEST_ZONE="" # gcp zone with resources

for pool_idx in {1..3}; do
  echo -n "Pool ${pool_idx}:"

  gcloud compute storage-pools describe "comptest-v${pool_idx}" \
    --zone="$TEST_ZONE" \
    --format json \
    | jq '.status | {
      pool: ((.poolUsedCapacityBytes | tonumber) / (1024 * 1024 * 1024)),
      written: ((.poolUserWrittenBytes | tonumber) / (1024 * 1024 * 1024))
    }'
done
