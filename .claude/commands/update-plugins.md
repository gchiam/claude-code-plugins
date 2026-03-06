---
name: update-plugins
description: Poll GitHub for new gchiam-plugins releases and run marketplace update if a newer version is available
argument-hint: "[--interval <seconds>] [--timeout <seconds>]"
allowed-tools:
  - Bash
---

Poll GitHub releases for the `gchiam/claude-code-plugins` repository and run
`claude plugin marketplace update gchiam-plugins` if any plugin has a newer
release than the currently installed version.

## Arguments

Parse optional arguments:
- `--interval <seconds>`: How often to poll. Default: `5`
- `--timeout <seconds>`: Give up after this many seconds. Default: `120`

## Step 1: Read installed versions

Read `~/.claude/plugins/installed_plugins.json` and extract all entries where
the key ends with `@gchiam-plugins`. For each, record the plugin name and
installed version.

```bash
node -e "
const fs = require('fs');
const data = JSON.parse(fs.readFileSync(process.env.HOME + '/.claude/plugins/installed_plugins.json', 'utf8'));
const plugins = Object.entries(data.plugins)
  .filter(([k]) => k.endsWith('@gchiam-plugins'))
  .map(([k, v]) => ({ name: k.replace('@gchiam-plugins', ''), version: v[0].version }));
console.log(JSON.stringify(plugins));
"
```

## Step 2: Poll for a newer release

Poll in a loop with the configured interval until a newer release is found or
timeout is reached.

On each iteration:

1. Fetch the latest release tag:
```bash
curl -sf https://api.github.com/repos/gchiam/claude-code-plugins/releases/latest \
  | node -e "const d=require('fs').readFileSync('/dev/stdin','utf8'); console.log(JSON.parse(d).tag_name)"
```

2. The tag format is `<plugin>@<version>` (e.g. `git-absorb@1.0.0`). Parse the
   plugin name and version.

3. Check if an update or new install is needed:
   - If the released plugin is **not** in the installed list → it's a new plugin, break out of the loop.
   - If the released plugin **is** in the installed list, compare versions:
```bash
node -e "
const [a, b] = process.argv.slice(1);
const parse = v => v.split('.').map(Number);
const [aMaj, aMin, aPatch] = parse(a);
const [bMaj, bMin, bPatch] = parse(b);
const newer = bMaj > aMaj || (bMaj === aMaj && bMin > aMin) || (bMaj === aMaj && bMin === aMin && bPatch > aPatch);
process.exit(newer ? 0 : 1);
" <installed_version> <release_version>
```
   If newer: break out of the loop.

4. If neither condition met: print `[<timestamp>] No new release yet (latest: <tag>). Checking again in <interval>s...` then sleep.

5. If timeout reached: print `Timed out after <timeout>s. No new release found.` and stop.

## Step 3: Install or update

Once a new or updated release is detected:

**If it's a version bump of an installed plugin**, show:
```
New release found: <tag> (installed: <installed_version>)
Running: claude plugin marketplace update gchiam-plugins
```
Run:
```bash
claude plugin marketplace update gchiam-plugins
```
On success show:
```
Done. gchiam-plugins updated to <version>.
```

**If it's a net-new plugin** (not currently installed), show:
```
New plugin available: <tag>
Running: claude plugin install <plugin-name>@gchiam-plugins
```
Run:
```bash
claude plugin install <plugin-name>@gchiam-plugins
```
On success show:
```
Done. <plugin-name>@<version> installed.
```
