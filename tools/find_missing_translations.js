const fs = require('fs');
const path = require('path');
const basePath = path.join('lib','l10n','app_en.arb');
const locales = ['fr','sw','rw'];

function load(p) {
  return JSON.parse(fs.readFileSync(p,'utf8'));
}

const base = load(basePath);
const baseKeys = Object.keys(base).filter(k => !k.startsWith('@'));
for (let loc of locales) {
  const p = path.join('lib','l10n',`app_${loc}.arb`);
  if (!fs.existsSync(p)) { console.log(`${loc}: file not found`); continue; }
  const obj = load(p);
  const keys = Object.keys(obj).filter(k => !k.startsWith('@'));
  const missing = baseKeys.filter(k => !keys.includes(k));
  console.log(`${loc}: ${missing.length} missing`);
  missing.forEach(k => console.log('  -', k));
}
