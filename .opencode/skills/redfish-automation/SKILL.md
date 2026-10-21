---
name: redfish-automation
description: Unattended 5-hour maintenance loop for redfishopenbmc — official docs scout, DMTF emulator tests, safe code/UI iteration, and append-only tracking.
---

# Redfish 5-Hour Automation Runbook

You are the unattended maintainer for **`/home/tomi/redfishopenbmc`**. You have no
memory of previous runs; everything you need is in the repo. Follow this runbook
exactly, and leave `main` shippable.

## Mission

Every run must move the project forward without breaking it:

1. **Protect `main`** — `flutter analyze` zero issues and `flutter test` green.
2. **If green**, prefer official-docs and emulator work; if red or a confirmed
   P1 defect exists, repair that first.
3. **Always track** — append one run section to `automation-tracking.md`, update
   `FUTUREWORK.md`, and append `progress/journal.md`.
4. **Always verify** before committing; push only after verification passes.

## Non-negotiables

- Work only in `/home/tomi/redfishopenbmc`. Do not touch other projects.
- `export PATH="$HOME/flutter/bin:$PATH"` at the start.
- Never force-push, rewrite history, delete user files, or print secrets/PATs.
- Never use GitHub Issues. The tracker is `issues/open/` + `issues/closed/`
  (`python3 issues/issues.py`).
- Never commit `.dart_tool/`, `build/`, `.env`, credentials, keys, or logs.
- Never weaken production TLS to make a test pass.
- No interactive prompts. Use non-interactive commands with timeouts.
- **Time budget: 7200s.** Stop starting new work at ~75 minutes, then finalize:
  tests, tracking, commit, push, summary.

## 0. Preflight (10 minutes)

```bash
export PATH="$HOME/flutter/bin:$PATH"
cd /home/tomi/redfishopenbmc

git status --short --branch
git log --oneline -5
flutter --version
flutter analyze
flutter test
python3 issues/issues.py validate
```

Read, in this order:

```bash
cat FUTUREWORK.md
tail -n 120 automation-tracking.md
tail -n 120 progress/journal.md
cat .opencode/skills/redfish-issues/SKILL.md   # tracker rules
```

Record the baseline: analyze result, test count, current commit.

### Dirty working tree

A previous run may have crashed mid-edit. Do **not** discard anything.

```bash
git diff --stat
git stash list
```

- If the changes are clearly the previous automation's work and they pass
  analyze + tests, commit them as `chore: recover previous automation WIP`.
- Otherwise preserve them with
  `git stash push -u -m "automation-preflight-$(date +%s)"` and mention the
  stash in this run's tracking entry. Never run `git clean -fdx`.

## 1. Choose one primary workstream

Use this decision tree:

1. **REPAIR** if `flutter analyze` or `flutter test` is red, or a regression is
   confirmed. Fix that first; do not start docs/emulator/UI work.
2. **DOCS** or **EMULATOR** if the baseline is green. Alternate them; check the
   last few `automation-tracking.md` entries and pick whichever ran less
   recently. Start with DOCS on a fresh queue.
3. **FEATURE / REFACTOR** if a P1 correctness issue is confirmed, or if docs work
   produced a small, safe code fix. Prefer one issue from `issues/open/`.
4. **UI** must still get one small, tested increment on every green run when time
   permits (see §5). If not, say why in tracking.

Do not attempt multiple large workstreams. A finished, tested increment beats a
broad half-finished refactor.

## 2. DOCS workstream — official sources only

### 2.1 Pull docs

Create/refresh the mirror:

```bash
mkdir -p documentations/external/redfish/{spec,schemas,openbmc,mockup}
```

Authoritative sources (verify with `curl -sSIL` before downloading):

- Redfish Developer Hub: <https://redfish.dmtf.org/>
- DMTF schema index: <https://redfish.dmtf.org/schemas/v1/>
- Redfish specification DSP0266 (latest PDF is linked from the hub)
- DMTF Redfish Mockup Server: <https://github.com/DMTF/Redfish-Mockup-Server>
- DMTF published mockups (DSP2043): linked from the mockup-server README
- OpenBMC bmcweb docs:
  - <https://raw.githubusercontent.com/openbmc/bmcweb/master/docs/Redfish.md>
  - <https://raw.githubusercontent.com/openbmc/bmcweb/master/docs/REDFISH_CHECKLIST.md>
  - <https://raw.githubusercontent.com/openbmc/bmcweb/master/docs/OEM_SCHEMAS.md>

Download with a timeout and a browser user-agent where the site blocks curl:

```bash
curl -L --fail --max-time 120 -A "Mozilla/5.0" -o <dest> <url>
```

If a site returns 403 to curl, use the `webfetch` tool or the alternate
`redfish.dmtf.org` URL; record the exact URL that worked. Do not scrape blogs or
unofficial summaries.

**Budget:** max 25 MB per file and 50 MB of new downloads per run. For larger
artifacts, store URL + SHA-256 + extracted notes instead of the binary. Never
commit a giant PDF just because it exists.

### 2.2 Record provenance

Update `documentations/external/README.md` with a manifest table:

| File | Source URL | Fetched (UTC) | SHA-256 | Bytes | Notes |
|---|---|---|---|---|---|

Also record the upstream commit SHA for GitHub sources and the spec version for
DMTF PDFs. Verify `sha256sum` after download.

### 2.3 Audit code against docs

Create/maintain `documentations/external/redfish/REQUIREMENTS.md`:

| Requirement | Source (section/URL) | Code | Test | Status |
|---|---|---|---|---|

- Trace each requirement to a file and a test.
- Prefer fixing small, safe gaps immediately (with tests).
- Put larger gaps in `FUTUREWORK.md` as `DOCS-*` or `#NNN` items with the source
  URL and section number.
- Do not invent requirements. If a behaviour is vendor-specific, mark it
  OpenBMC/OEM and cite `bmcweb` or `OEM_SCHEMAS.md`.
- Keep `documentations/redfish_reference/` consistent; update its README when
  the snapshot changes.

## 3. EMULATOR workstream — official DMTF mockup server

Use the official Python **Redfish-Mockup-Server** and the existing mockup fixture
`test/fixtures/redfish/dmtf_mockup`.

```bash
# one-time per run (outside the repo)
rm -rf /tmp/redfish-mockup-server /tmp/redfish-emulator-venv
git clone --depth 1 https://github.com/DMTF/Redfish-Mockup-Server /tmp/redfish-mockup-server
python3 -m venv /tmp/redfish-emulator-venv
. /tmp/redfish-emulator-venv/bin/activate
pip install -q -r /tmp/redfish-mockup-server/requirements.txt
```

Generate a short-lived self-signed cert for localhost:

```bash
openssl req -x509 -newkey rsa:2048 -nodes -days 2 \
  -keyout /tmp/redfish-emulator-key.pem \
  -out /tmp/redfish-emulator-cert.pem \
  -subj "/CN=127.0.0.1" \
  -addext "subjectAltName=IP:127.0.0.1,DNS:localhost"
```

Start it over HTTPS. The fixture is short-form (no top-level `redfish/`
directory), so include `-S`:

```bash
python /tmp/redfish-mockup-server/redfishMockupServer.py \
  -H 127.0.0.1 -p 8443 \
  -D test/fixtures/redfish/dmtf_mockup \
  -s --cert /tmp/redfish-emulator-cert.pem \
  --key /tmp/redfish-emulator-key.pem -S \
  > /tmp/redfish-emulator.log 2>&1 &
```

Wait for health before testing:

```bash
for i in $(seq 1 30); do
  curl -ksSf https://127.0.0.1:8443/redfish/v1/ >/dev/null && break
  sleep 1
done
curl -ksS https://127.0.0.1:8443/redfish/v1/ | head -c 400
```

If `-S` is wrong, test both forms and record which works. Always stop the server
with `trap` in scripts; never leave a background process running.

### 3.1 Add/maintain tests

- Put integration tests in `test_integration/emulator/`, **not** under `test/`.
  Plain `flutter test` must never require the emulator.
- Configure the URL with
  `--dart-define=REDFISH_EMULATOR_URL=https://127.0.0.1:8443` and read it with
  `const String.fromEnvironment(...)`.
- Use `ConnectionProfile(allowSelfSigned: true)` only in the test profile.
- Cover: service-root discovery, BFS/feature detection, systems, sensors,
  firmware inventory, KVM capability, error mapping, and power actions where
  supported.
- If the mockup server returns 405/501 for an action, assert the client's
  normalized error rather than silently skipping.
- Add `tool/emulator/run_tests.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
# start server, trap cleanup, wait for health, run:
flutter test test_integration/emulator \
  --dart-define=REDFISH_EMULATOR_URL=https://127.0.0.1:8443
```

Pin the emulator commit in the script/manifest. If the official server cannot
work in this environment, record the exact blocker in `FUTUREWORK.md`; a minimal
HTTPS fixture server is an acceptable fallback but must be labelled as such.

### 3.2 Evaluate the richer emulator only if needed

`DMTF/Redfish-Interface-Emulator` supports more dynamic actions. Evaluate it only
if the mockup server blocks meaningful tests. Record the decision and pin the
commit.

## 4. CODE / TEST / REFACTOR workstream

- Pick the highest-priority unblocked item from `FUTUREWORK.md` or
  `issues/open/`. Read the issue's acceptance criteria first.
- Write or extend a failing test when practical, then implement.
- Follow existing patterns: feature folders, Riverpod providers, Dio,
  `RedfishClient`, capability-gated UI.
- Keep changes small. Run targeted tests during work, then the full suite.
- Coverage target **≥ 80%** for the touched feature.
- Do not change public behaviour without updating tests and docs.
- Refactor only with a green baseline before and after.
- Close an issue only when every acceptance box is checked and all gates pass:
  `python3 issues/issues.py close NNN --reason "..."`.
- Update the issue's `Progress Log`, `progress/journal.md`, and (for P1/P2)
  `progress/progress_summary.md`.

## 5. UI workstream — one focused improvement per green run

- Pick one item from the UI section of `FUTUREWORK.md`.
- Keep the design capability-gated: no hardcoded feature tabs or controls.
- Prioritise empty/loading/error states, accessibility, responsive layout, and
  visual consistency over new decoration.
- Add/extend widget tests. Verify no overflow at **320 / 800 / 1300 px** widths.
- Use existing `AppTheme`, breakpoints, badges, and card patterns.
- Do not add a dependency for a one-off effect. If a dependency is justified,
  update `pubspec.yaml` + `pubspec.lock` and tests.
- If the primary workstream consumed the budget, skip UI and state why in
  tracking; do not rush an untested redesign.

## 6. Verification gate (mandatory)

Run all of these before committing:

```bash
export PATH="$HOME/flutter/bin:$PATH"
cd /home/tomi/redfishopenbmc

dart format lib test test_integration tool 2>/dev/null || true
flutter analyze
flutter test
python3 issues/issues.py validate
git diff --check
```

Requirements:

- `flutter analyze`: **0 issues**
- `flutter test`: **all pass** (record `+N ~M` counts)
- `issues.py validate`: OK if `issues/` touched
- `git diff --check`: clean
- Secret scan: inspect the staged diff for tokens/passwords before commit.

If a check fails:

1. Fix it if the fix is small and safe.
2. Otherwise revert **only this run's changes**:
   `git stash push -u -m "auto-failed-<timestamp>"` (preserves work) and record
   the failure + stash name in tracking. Do not reset the whole repo.

## 7. Tracking, commit, push

### 7.1 Append to `automation-tracking.md`

Append exactly one section at the **end**:

```markdown
## YYYY-MM-DD HH:MM — MODE

- **Baseline:** analyze X; tests N passed / M skipped; starting commit abc1234.
- **Primary work:** one paragraph.
- **Docs:** URLs fetched, files added, requirements found (or "none this run").
- **Emulator:** server/test status (or "none this run").
- **Code/tests:** files changed, issue IDs, new tests.
- **UI:** what changed and which widget tests cover it (or why skipped).
- **Verification:** analyze 0; tests N passed / M skipped; issues validate OK.
- **Commit:** abc1234 — message; pushed: yes/no (+ reason if no).
- **Next:** three concrete actions for the next run.
```

### 7.2 Update `FUTUREWORK.md`

- Check off completed items with `(run YYYY-MM-DD, commit abc1234)`.
- Add newly discovered items with source URLs.
- Keep the list ordered P0 → P1 → P2; mark blockers `[!]`.
- Update the `Last updated` line.

### 7.3 Journal

Append a `## YYYY-MM-DD — agent:redfish-automation — #NNN` section to
`progress/journal.md` with Done / Decisions / Next / Issues touched. If a P1/P2
issue closed, update `progress/progress_summary.md`.

### 7.4 Commit and push

Stage only intended files:

```bash
git add lib/ test/ test_integration/ tool/ documentations/ \
  automation-tracking.md FUTUREWORK.md progress/ issues/ \
  pubspec.yaml pubspec.lock README.md DEVELOPMENT.md .opencode/
git diff --cached --check
git diff --cached --stat
git commit -m "auto: <mode> — <short summary> (run YYYY-MM-DD HH:MM)"
git push origin main
```

- If push fails, keep the commit and record the failure. Do not retry endlessly.
- Never `git add -A`; never stage secrets, builds, or caches.
- Never force-push.

## 8. Final output

Print a concise report for the scheduler email (max ~40 lines):

```
MODE: DOCS|EMULATOR|REPAIR|FEATURE|UI|REFACTOR
BASELINE: analyze 0, tests 231
DID: ...
DOCS: ...
EMULATOR: ...
CODE: ...
UI: ...
VERIFY: analyze 0, tests N, issues OK
COMMIT: abc1234 (pushed yes/no)
NEXT: 1) ... 2) ... 3) ...
```

Do not include secrets, tokens, or long logs.
