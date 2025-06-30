function parseDisks(series) {
  const disks = new Map();

  for (const { metric, data } of series) {
    const deviceName = metric.labels.device_name;
    let disk = disks.get(deviceName);
    if (!disk) {
      disk = [];
      disks.set(deviceName, disk);
    }

    for (const sample of data) {
      disk.push({ start: sample.x0 / 1e3, end: sample.x / 1e3 });
    }
  }

  return disks;
}

function merge(interval) {
  const out = [];

  for (const [i, item] of interval.entries()) {
    if (i == 0) {
      out.push(item);
      continue;
    }

    const prev = out[out.length - 1];
    if (prev.end == item.start) {
      prev.end = item.end;
      continue;
    }

    out.push(item);
  }

  return out.map(item => ({ ...item, len: item.end - item.start }));
}

function main() {
  const series = require('./series-2.json');
  const disks = parseDisks(series);
  const occurrences = [ ...disks.values() ].flatMap(merge);
  const lengths = occurrences.map(item => item.len);

  console.log({
    amount: occurrences.length,
    min: Math.min(...lengths),
    max: Math.max(...lengths),
    avg: lengths.reduce((acc, item) => acc + item, 0) / lengths.length,
  });
}

main();
