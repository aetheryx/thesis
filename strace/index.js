const fs = require('node:fs');
const split = require('split2');

const files = [];
const fds = new Map();

const STRACE_FMT = /(?<name>[a-z]+)\((?<args>.*)\) += (?<ret>.*) <(?<dur>.*)>/;

function onLine(pid, line) {
  if (line.startsWith('---')) return;
  
  const { groups } = line.match(STRACE_FMT);
  const args = groups.args.split(', ');
  if (groups.name == 'openat') {
    const path = args[1].slice(1, -1);
    const fd = groups.ret;
    const key = `${pid}.${fd}`;

    if (fds.has(key)) {
      files.push(fds.get(key));
      fds.delete(key);
    }
    
    fds.set(key, {
      path,
      bytes: {
        read: 0,
        write: 0,
      }
    });
    return;
  }
  
  for (const fd_call of ['read', 'write']) {
    if (groups.name != fd_call) continue;
    
    const fd = args[0];
    const file = fds.get(`${pid}.${fd}`);
    if (!file) continue;
    
    const bytes = Number(args.at(-1));
    file.bytes[fd_call] += bytes;
  }
}

async function main() {
  const traces = fs.readdirSync('./traces');
  
  await Promise.all(traces.map(filename => new Promise(resolve => {
    const pid = filename.split('.').at(-1);
    fs.createReadStream(`./traces/${filename}`)
      .pipe(split())
      .on('data', line => onLine(pid, line))
      .on('close', resolve);
  })));
}

main().then(() => {
  for (const f of fds.values()) files.push(f);
  let totals = {
    local: { cnt: 0, read: 0, write: 0 },
    network: { cnt: 0, read: 0, write: 0}
  };

  for (const f of files) {
    if (f.path.startsWith('/sys') || f.path.startsWith('/proc')) {
      continue;
    }
    
    const isLocal = f.path.startsWith('/home/user/.cache/bazel') || f.path.startsWith('/tmp');
    const key = isLocal ? 'local' : 'network';

    totals[key].cnt++;
    totals[key].read += f.bytes.read;
    totals[key].write += f.bytes.write;
  }
  
  console.log({ totals });
})
