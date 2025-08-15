#!/usr/bin/env zx

const gcpRegion = process.env.GCP_REGION;
const storagePoolName = process.env.STORAGE_POOL_NAME;
const projectName = process.env.PROJECT_NAME;
const concurrency = Number(process.env.CONCURRENCY);

const snapshots = await within(async () => {
  const alreadyCreatedRaw = await $`
    gcloud compute disks list \
      --project=${projectName} --zones=${gcpRegion} \
      --filter=${`storagePool~${storagePoolName}`} \
      | awk '{ print $1 }'
  `;
  const alreadyCreated = new Set(alreadyCreatedRaw.stdout.trim().split("\n").slice(1));

  return require("../data/prepared_disks.json")
    .filter(disk => !alreadyCreated.has(`${disk.devpod}-hd-test`));
});

async function main() {
  const threads = [];

  for (let i = 0; i < concurrency; i++) {
    threads.push(thread());
    await sleep(1000);
  }

  await Promise.all(threads);
}

async function thread() {
  while (snapshots.length > 0) {
    const target = snapshots.pop();
    await migrate(target)
      .catch(err => {
        console.error("failed to migrate", target, err);
        snapshots.push(target);
      });

    console.log(`remaining:`, snapshots.length);
  }
}

async function migrate({ devpod, snapshot, size }) {
  console.log("creating", `${devpod}-hd-test`);
  await $`
    gcloud compute disks create ${devpod}-hd-test \
      --project ${projectName} --zone ${gcpRegion}
      --type hyperdisk-balanced --provisioned-iops=3000 --provisioned-throughput=140 \
      --source-snapshot=${snapshot} \
      --size=${size}Gi \
      --storage-pool=projects/${projectName}/zones/${gcpRegion}/storagePools/${storagePoolName}
  `;
}

main();
