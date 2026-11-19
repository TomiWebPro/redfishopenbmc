# Redfish Multi-Department Coordination (binding for all scheduler jobs)

> Goal: parallel speed + single-writer accuracy, ported from Cognithor COORDINATION.md.
> Only 2 issues remain open (#009, #021), both partly externally blocked on platform
> WebView + BMC TLS/self-signed validation. Departments exist to unblock and split
> first, parallelize second — never verification-only churn.

## Departments = fixed single-writer path ownership

| Dept | Worktree / branch | Owns (writes) | Never writes |
|---|---|---|---|
| rf-model | `~/redfish-wt/model` / `build/rf-model` | `lib/features/kvm/models/**`, `lib/redfish/discovery/**` | views, services, tooling |
| rf-ui | `~/redfish-wt/ui` / `build/rf-ui` | `lib/features/kvm/views/**`, `lib/features/systems/**` widgets | models, services, tooling |
| rf-service | `~/redfish-wt/service` / `build/rf-service` | `lib/features/kvm/kvm_service.dart`, controllers/providers, `lib/redfish/client/**` | views, models, tooling |
| rf-tooling | `~/redfish-wt/tooling` / `build/rf-tooling` | `test/**` (tool/coverage), `tool/**`, `test/fixtures/**`, `.github/workflows/**`, `pubspec*` | `lib/` product code |
| rf-platform | `~/redfish-wt/platform` / `build/rf-platform` | new `lib/features/kvm/platform/**` only (WebView/TLS validation spike + conditional imports) | production TLS behavior |
| rf-audit | `~/redfishopenbmc` (main) | new files in `issues/open/`, `FUTUREWORK.md` gap entries | existing issues, code |
| rf-ideate | `~/redfishopenbmc` (main) | `queues/*.md`; splits #009/#021 into unblocked sub-issues | code |
| rf-check | per-dept worktree (read-only, commits nothing) | none | everything committed |
| rf-gate | `~/redfishopenbmc` (main) | merges `build/rf-*` → main, `FUTUREWORK.md`, `progress/`, `automation-tracking.md`, issue close/reopen | product code it doesn't own |

## Hard rules

1. Builders: one queue item per run, one commit per item. Work only your `queues/<dept>.md`. Stage only owned paths.
2. Missing shared helper? Do NOT edit another dept's paths — file it in `queues/_lib-requests.md` (gate owns cross-cutting helpers).
3. Cross-cutting issues are split by rf-ideate into one sub-issue per dept, chained via scheduler `link child --after parent`. Until split, they stay queued, never assigned.
4. Issue fields (mandatory): `Dept: <single dept>`, `Verify: <exact commands>`. Audit rejects issues without them.
5. Check jobs are read-only: verify branch (analyze + targeted tests + Verify commands + owned-paths only), commit nothing, record verdict per branch.
6. Only rf-gate merges to main. Gate merges ONLY branches whose latest `<dept>-check` verdict is PASS; then re-runs `flutter analyze`, full `flutter test`, all three coverage gates, `issues.py validate`, and the 85-test DMTF emulator suite when `lib/` wire/fixtures/tool changed. No new commits → NO-OP exit 0.
7. Chains: `rf-audit --trigger rf-ideate`; `rf-ideate --trigger` all builders (fan-out); builders `--trigger` their check (SUCCESS only); checks `--trigger rf-gate`. Timers are fallback.
8. Commit messages: `auto: <dept> — <short summary> (run YYYY-MM-DD HH:MM)`. Check jobs commit nothing. Never force-push.
9. RED→GREEN is mandatory per item (this repo's culture — preserve it). No WebView/protocol dependency without platform validation; never weaken production TLS.
10. `queues/*.md` is the only queue. When empty, do Never-empty-well work (malformed-payload tolerance, a11y, coverage) — never declare QUEUE-EMPTY, never touch others' paths.
