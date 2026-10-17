// Parses every YAML file given as argument; exits non-zero on the first syntax error.
const fs = require('fs');
const yaml = require('js-yaml');
for (const f of process.argv.slice(2)) {
  yaml.loadAll(fs.readFileSync(f, 'utf8'));
  console.log(`ok ${f}`);
}
