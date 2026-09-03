import { readFileSync, readdirSync } from 'node:fs';
import { extname, join } from 'node:path';

const source = readFileSync('src/main.pp', 'utf8');
if (!source.includes('@ossh/src/ossh.pp')) {
  throw new Error('ppos must compose through ossh');
}
if (!source.includes('@ppnet/src/ppnet.pp')
    || !source.includes('@ppnet/src/oscore_port.pp')) {
  throw new Error('ppos must compose through the published ppnet port');
}
if (!source.includes('import "agent.pp"')) {
  throw new Error('ppos v0.3 must compose the Agent host');
}
if (source.includes('@oscore/') || source.includes('@osbare/')) {
  throw new Error('ppos source must preserve the ossh -> oscore -> osbare dependency chain');
}
if (/\b(outb|inb|cli|sti|hlt)\s*\(/.test(source) || /0xB8000/i.test(source)) {
  throw new Error('ppos product policy cannot access hardware directly');
}

const textExtensions = new Set([
  '.c', '.h', '.lock', '.md', '.mjs', '.pp', '.sh', '.toml', '.yml',
  '.zig',
]);
function checkTextTree(directory) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    if (['.git', 'build', 'target'].includes(entry.name)) continue;
    const path = join(directory, entry.name);
    if (entry.isDirectory()) {
      checkTextTree(path);
      continue;
    }
    if (!textExtensions.has(extname(entry.name)) && entry.name !== 'VERSION') continue;
    const content = readFileSync(path, 'utf8');
    if (!content.endsWith('\n') || content.endsWith('\n\n')) {
      throw new Error(`${path}: expected exactly one final newline`);
    }
    if (/[ \t]+$/m.test(content)) throw new Error(`${path}: trailing whitespace`);
  }
}

checkTextTree('.');
if (readFileSync('VERSION', 'utf8').trim() !== '0.3.0') {
  throw new Error('VERSION must be 0.3.0');
}
if (!readFileSync('pp.toml', 'utf8').includes('tag = "v0.1.1"')
    || !readFileSync('pp.toml', 'utf8').includes('tag = "v0.2.2"')) {
  throw new Error('ppos v0.3 must use published osrt and ppnet tags');
}
console.log('PPOS REPOSITORY PASS');
