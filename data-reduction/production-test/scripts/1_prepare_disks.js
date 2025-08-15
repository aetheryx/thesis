#!/usr/bin/env zx

const devpods = require("../data/devpods.json");
const pvcs = require("../data/pvcs.json").items;
const snapshots = require("../data/snapshots.json");

let notFound = 0;

function getSnapshots() {
  const ret = [];

  for (const devpod of devpods) {
    if (devpod.state != 'running') continue;
    if (devpod.flavor == 'base-arm') continue;
    if (Date.now() - new Date(devpod.created_at).getTime() < 1000 * 60 * 60 * 24 * 1) continue;

    const pvc = pvcs.find((v) => v.metadata.labels?.name == devpod.devpodName);
    const devpodSnapshots = snapshots.filter((v) =>
      v.sourceDisk.endsWith(pvc.spec.volumeName)
    )
    if (devpodSnapshots.length == 0) {
        notFound++;
        continue;
    }

    const snapshot = devpodSnapshots.reduce((newer, older) => {
      const isNewer = new Date(newer.creationTimestamp).getTime() > new Date(older.creationTimestamp).getTime();
      return isNewer ? newer : older;
    });

    ret.push({
      devpod: devpod.devpodName,
      snapshot: snapshot.name,
      size: Number(snapshot.diskSizeGb),
    });
  }

  return ret;
}

async function main() {
  const snapshots = getSnapshots();
  fs.writeFileSync("../data/prepared_disks.json", JSON.stringify(snapshots, null, 2));
  console.log('Wrote disks successfully', {
    count: snapshots.length,
    notFound,
  });
}

main();
