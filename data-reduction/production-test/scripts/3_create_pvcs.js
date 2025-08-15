#!/usr/bin/env zx

const snapshots = require("../data/prepared_disks.json");
const concurrency = Number(process.env.CONCURRENCY);
const gcpRegion = process.env.GCP_REGION;

async function main() {
  const threads = [];

  for (let i = 0; i < concurrency; i++) {
    threads.push(thread());
  }

  await Promise.all(threads);
}

async function thread() {
  while (snapshots.length > 0) {
    const target = snapshots.pop();
    await create(target)
      .catch(err => {
        console.error("failed to migrate", target, err);
        snapshots.push(target);
      });

    console.log(`${snapshots.length} remaining`);
  }
}

async function create({ devpod, size }) {
  console.log("creating", `${devpod}-hd-test`);
  const diskPath = `projects/${projectName}/zones/${gcpRegion}/disks/${devpod}-hd-test`;
  await $`
    ytt \
      -v "disk=${devpod}-hd-test" \
      -v "size=${size}Gi" \
      -v "diskPath=${diskPath}" \
      -f ./pvc.yaml \
      | kubectl apply -f -
  `;
}

main();
