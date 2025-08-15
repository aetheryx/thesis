#!/usr/bin/env zx

const disks = require("../data/prepared_disks.json")
  .map((disk, i) => ({
    disk: `${disk.devpod}-hd-test`,
    idx: i,
    wait: 120,
  }))

const nodes = Number(process.env.NODES);
const concurrency = Number(process.env.CONCURRENCY);

async function main() {
  const threads = [];

  for (let i = 0; i < concurrency; i++) {
    await sleep(1000 + (Math.random() * 5000));
    threads.push(thread(i));
  }

  await Promise.all(threads);
}

async function thread(threadID) {
  while (disks.length > 0) {
    const disk = disks.shift();
    await mount(disk, threadID);
    console.log(`${disks.length} remaining`);
  }
}

function exists(disk) {
  if (!fs.existsSync(`data/df_outs/${disk}.txt`)) return false;

  const content = fs.readFileSync(`data/df_outs/${disk}.txt`, "utf-8");
  return content.includes(`/mnt/test-disks/${disk}`);
}

async function mount(disk, threadID) {
  if (exists(disk.disk)) {
    console.log("results already exist", disk);
    return;
  }

  await $`
    ytt \
      -v "nodeIdx=${threadID % nodes}" \
      -v "disk=${disk.disk}" \
      -v "diskIdx=${disk.idx}" \
      -f ./pod.yaml \
      | kubectl apply -f -
  `;

  try {
    await $`
      kubectl wait \
        --for=jsonpath='{.status.phase}'=Succeeded \
        pod/ingest-pod-${disk.idx} \
        -n hyperdisk-experimentation \
        --timeout=${disk.wait}s
    `;

    await sleep(100);
    const logs = await within(async () => {
      $.verbose = false;
      return $`
        kubectl logs ingest-pod-${disk.idx} -n hyperdisk-experimentation
      `;
    })
    fs.writeFileSync(`data/df_outs/${disk.disk}.txt`, logs.stdout);
  } catch (e) {
    console.error("pod failed", disk, e.stdout, e.stderr);
    disk.wait += 120;
    disks.push(disk);
  } finally {
    await $`kubectl delete pod ingest-pod-${disk.idx} -n hyperdisk-experimentation`;
  }
}

main();
