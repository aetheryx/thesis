#!/usr/bin/env zx

const preparedDisks = require("../data/prepared_disks.json");
const oldCapacity = preparedDisks.reduce((acc, disk) => acc + Number(disk.size), 0);
const gcpRegion = process.env.GCP_REGION;
const storagePoolName = process.env.STORAGE_POOL_NAME;

const dfUsage = await within(async () => {
  const lines = await $`
    cat data/df_outs/* | grep /mnt/test-disks/
  `;

  const entries = lines.stdout.trim().split('\n').map(line => {
    const segments = line.split(/\s+/);
    return {
      usedBytes: BigInt(segments[2]) * 1024n,
      mount: segments[5],
    };
  });

  const totalUsedBytes = entries.reduce((acc, entry) => acc + entry.usedBytes, 0n);
  return Number(totalUsedBytes / (1024n ** 3n));
});

const poolUsage = await within(async () => {
  const dataRaw = await $`
    gcloud compute storage-pools describe ${storagePoolName} --zone=${gcpRegion} --format json
  `;

  const data = JSON.parse(dataRaw.stdout);
  return Number(BigInt(data.status.poolUsedCapacityBytes) / (1024n ** 3n));
});

const totalReduction = 1 - (poolUsage / oldCapacity);
const compressionRatio = 1 - (poolUsage / dfUsage);

console.table({
  'Old total capacity': `${oldCapacity.toLocaleString()} GiB`,
  'User bytes written (df)': `${dfUsage.toLocaleString()} GiB`,
  'Pool usage': `${poolUsage.toLocaleString()} GiB`,
  'Compression reduction': `-${(compressionRatio * 100).toFixed(2)}%`,
  'Total capacity reduction': `-${(totalReduction * 100).toFixed(2)}%`,
});
