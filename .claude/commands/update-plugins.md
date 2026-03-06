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

## Step 2: Poll for updates

Poll in a loop with the configured interval until one or more updates are found or
timeout is reached.

On each iteration:

1. Fetch **all** releases (not just latest) to catch multiple updates at once:
```bash
curl -sf "https://api.github.com/repos/gchiam/claude-code-plugins/releases?per_page=100" \
  | node -e "
const releases = JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
// Deduplicate: keep only the highest version per plugin
const latest = {};
for (const r of releases) {
  const match = r.tag_name.match(/^(.+)@(\d+\.\d+\.\d+)$/);
  if (!match) continue;
  const [, name, version] = match;
  if (!latest[name]) latest[name] = version;
  // releases are sorted newest-first, so first occurrence is highest
}
console.log(JSON.stringify(latest));
"
```

2. For each plugin in the releases map, check against installed versions:
   - If the plugin is **not** in the installed list → it's a new plugin, add to pending actions.
   - If the plugin **is** in the installed list, compare versions using semver:
     - If release version > installed version → add to pending actions.

3. If **no** pending actions: print `[<timestamp>] All plugins up to date (checked <N> releases). Checking again in <interval>s...` then sleep.

4. If **pending actions found**: break out of the loop.

5. If timeout reached: print `Timed out after <timeout>s. No updates found.` and stop.

## Step 3: Install or update

For each pending action collected in Step 2:

**If it's a version bump of an installed plugin**, show:
```
New release found: <plugin>@<version> (installed: <installed_version>)
Running: claude plugin marketplace update gchiam-plugins
```
Run once (covers all version bumps):
```bash
claude plugin marketplace update gchiam-plugins
```
On success show:
```
Done. gchiam-plugins updated.
```

**If it's a net-new plugin** (not currently installed), show:
```
New plugin available: <plugin>@<version>
Running: claude plugin install <plugin>@gchiam-plugins
```
Run for each new plugin:
```bash
claude plugin install <plugin>@gchiam-plugins
```
On success show:
```
Done. <plugin>@<version> installed.
```
