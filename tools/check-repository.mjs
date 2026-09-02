import { readFileSync, readdirSync } from 'node:fs';
import { extname, join } from 'node:path';

const source = readFileSync('src/main.pp', 'utf8');
if (!source.includes('@ossh/src/ossh.pp')) {
  throw new Error('ppos must compose through ossh');
}
if (!source.includes('@ppnet/src/ppnet.pp')
    || !source.includes('@ppnet/src/oscore_port.pp')) {
  throw new Error('ppos v0.2 must compose through the published ppnet port');
}
if (source.includes('@oscore/') || source.includes('@osbare/')) {
  throw new Error('ppos source must preserve the ossh -> oscore -> osbare dependency chain');
}
if (/\b(outb|inb|cli|sti|hlt)\s*\(/.test(source) || /0xB8000/i.test(source)) {
  throw new Error('ppos product policy cannot access hardware directly');
}

const textExtensions = new Set(['.md', '.pp', '.sh', '.mjs', '.toml', '.yml']);
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
console.log('PPOS REPOSITORY PASS');
