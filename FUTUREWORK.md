# FUTUREWORK

Living queue for the **`redfish-automation`** job (every 5 hours).

> Read this file first. Pick **one primary workstream** per run, finish it, verify
> it, then update this file. Detailed acceptance criteria live in `issues/open/`;
> reference the issue ID instead of duplicating it. New gaps discovered from
> official docs go here with a source URL.

- **Last updated:** 2026-10-22 14:01 (EMULATOR run)
- **Current focus:** emulator harness live (EMU-1..4); next DOCS-3 DSP0266 audit + P1 #014/#015
- **Run cadence:** `0 */5 * * *`
- **Model:** `opencode/deepseek-v4.1-flash-free`
- **Status keys:** `[ ]` todo · `[~]` in progress · `[x]` done · `[!]` blocked

## Selection rules

1. **P0 first.** If `flutter analyze` or `flutter test` is red, repair that before
   any new work. Never start a feature on a red baseline.
2. **Then alternate DOCS and EMULATOR** when the baseline is green. Use the most
   recent `automation-tracking.md` entries to pick whichever has gone longest
   without a run.
3. **Then confirmed P1 defects** (`#014`, `#015`, `#027`), then P2/P3 issues.
4. **Every green run should land one small UI/test improvement** when the primary
   workstream leaves time. If not, say why in the tracking entry.
5. One primary workstream per run. Prefer a finished, tested increment over a
   broad half-finished refactor.

## P0 — keep `main` green

- [ ] Keep `flutter analyze` at **0 issues** and the full `flutter test` suite green.
- [ ] Keep `python3 issues/issues.py validate` green whenever `issues/` changes.
- [ ] Never leave the working tree dirty at the end of a run: commit intended work
      or stash it with a clear label; never discard user work.
- [ ] Never force-push, rewrite history, print credentials, or commit secrets.
- [ ] If a change cannot be made green, revert only that change and record why.

## P1 — official docs and compliance

- [x] **DOCS-1** Establish `documentations/external/` as the official-docs mirror:
      DMTF Redfish spec, schema index, mockup, and OpenBMC bmcweb docs. Add a
      manifest with URL, fetch time, SHA-256, size, and license/notes.
      Start at `https://redfish.dmtf.org/`, `https://redfish.dmtf.org/schemas/v1/`,
      `https://github.com/DMTF/Redfish-Mockup-Server`, and
      `https://github.com/openbmc/bmcweb/tree/master/docs`.
      (run 2026-10-22, commit c8dc7e1 — mirror + manifest + REQUIREMENTS.md live;
      re-fetch on upstream change only)
- [~] **DOCS-2** Refresh the DMTF schema/mockup snapshot used by
      `documentations/redfish_reference/` and `test/fixtures/redfish/`; verify the
      provenance section in `documentations/redfish_reference/README.md` is current.
      (provenance note added 2026-10-22; full fixture refresh pending)
- [ ] **DOCS-3** Audit the latest Redfish specification (DSP0266, currently linked
      from `https://redfish.dmtf.org/`) against the client's discovery, auth,
      error, PATCH/ETag, task, and subscription behaviour. Record gaps with
      section numbers and source URLs.
      (14-row trace started in `documentations/external/redfish/REQUIREMENTS.md`
      2026-10-22; continue auditing EventService/Subscriptions and TaskService)
- [ ] **DOCS-4** Audit OpenBMC bmcweb's `docs/Redfish.md`,
      `docs/REDFISH_CHECKLIST.md`, and `docs/OEM_SCHEMAS.md`; document where our
      feature detection differs from bmcweb's actual behaviour.
- [ ] **DOCS-5** Map every `SystemFeatures` flag to a spec citation and a test.
      Add a table under `documentations/redfish_reference/` or
      `documentations/external/redfish/REQUIREMENTS.md`.
- [ ] **DOCS-6** Keep the downloaded corpus bounded: max 25 MB per file and 50 MB
      of new downloads per run. For larger artifacts store the URL + hash +
      extracted notes instead of the binary.
- [ ] **DOCS-7** Event subscription support: client has no EventService /
      Subscriptions implementation yet; DSP0266 §14 "Eventing" + `EventService.json`
      now mirrored (schemas/v1/EventService.json). Decide: implement subscribe +
      SSE/webhook handling, or document as out-of-scope with rationale.

## P1 — emulator and integration tests

- [x] **EMU-1** Stand up the official DMTF Redfish-Mockup-Server over HTTPS using
      `test/fixtures/redfish/dmtf_mockup` (public-rackmount1) and a generated
      self-signed cert. Health-check `GET /redfish/v1/` before tests.
      (run 2026-10-22, commit 81dfb8f — pin `23d21f9a`, script
      `tool/emulator/run_tests.sh`, port 8443)
- [x] **EMU-2** Add end-to-end tests under `test_integration/emulator/` (outside
      `test/` so plain `flutter test` never needs the emulator). Cover discovery,
      service-root traversal, systems, sensors, firmware inventory, and KVM
      capability detection.
      (run 2026-10-22, commit 81dfb8f — 11 tests in
      `test_integration/emulator/emulator_suite_test.dart`; skips without
      `REDFISH_EMULATOR_URL`)
- [~] **EMU-3** Cover auth and power actions where the emulator supports them.
      If an action is unsupported, assert the client's error mapping instead of
      skipping silently.
      (session + basic auth, reset action, 404 mapping done 2026-10-22;
      remaining: a richer emulator is needed to exercise 403/409/400 extended
      info paths — see EMU-5)
- [x] **EMU-4** Add `tool/emulator/run_tests.sh` that starts the server, waits for
      health, runs the integration tests, and always stops the server via `trap`.
      Pin the emulator commit and document it.
      (run 2026-10-22, commit 81dfb8f — verified end-to-end; trap cleanup
      confirmed; pin `23d21f9a` in the script + docs README)
- [ ] **EMU-5** Evaluate `DMTF/Redfish-Interface-Emulator` only if the mockup
      server cannot exercise the required dynamic actions. Record the decision.
      (mockup server covers discovery/sensors/firmware/KVM/power; dynamic
      error-action paths (403/409/400 + ExtendedInfo) would need the richer
      emulator)
- [x] **EMU-6** Do not loosen production TLS. Use `allowSelfSigned: true` only in
      the test profile; never add an HTTP/plaintext production path.
      (run 2026-10-22 — self-signed cert is `/tmp`-generated test-only;
      `allowSelfSigned` used only in `test_integration/emulator/` profile)

## P1 — confirmed code defects

- [ ] **#014** Fix `RedfishError` `@Message.ExtendedInfo` parsing.
- [ ] **#015** AuthManager: auth method, safe logout URI, session reuse/expiry.
- [ ] **#027** Verify the Flutter toolchain issue is stale; close it with evidence
      if `flutter analyze`/`flutter test` work, otherwise fix it.
- [ ] **#016** PATCH / `If-Match` / `@odata.etag` support.
- [ ] **#017** Discover the SessionService URI instead of assuming it.
- [ ] **#018** Fix discovery-cache stale replay/leak.
- [ ] **#022** Power: task polling, races, and error fixes.
- [ ] **#024** `profile_repository.clear()` orphaned passwords.
- [ ] **#026** Resolve duplicate auth fields.

## P2 — feature completeness

- [ ] **#006** System overview adaptive cards.
- [ ] **#007 / #019** Sensor monitoring, real-time telemetry, retry.
- [ ] **#008 / #020** Firmware update management, upload progress, task timeline.
- [ ] **#009 / #021** Remote KVM capability detection and console rendering.
- [ ] **#010** Hardening: secure storage, theming, accessibility, coverage.

## P2 — UI improvements (one small, tested increment per green run)

- [ ] **UI-1** Empty / loading / error states for dashboard, sensors, firmware, KVM.
- [ ] **UI-2** Accessibility: semantics labels, contrast, touch targets, focus order.
      (Health/Power badges semantic labels done 2026-10-22 — commit c8dc7e1;
      destructive power dialog label done 2026-10-22 — commit 81dfb8f; extend
      to cards, dialogs, tables)
- [ ] **UI-3** Responsive layout: no overflow at 320 / 800 / 1300 px widths; add
      widget tests for each breakpoint.
- [ ] **UI-4** Visual consistency for cards, badges, health/power colors, spacing.
- [ ] **UI-5** Power confirmation dialog: clearer destructive-action copy and
      disabled/busy states.
      (destructive copy + a11y label done 2026-10-22 — commit 81dfb8f; busy
      state on the dialog confirm button still pending)
- [ ] **UI-6** Sensor table: sorting/filtering, threshold highlighting, stale data.
- [ ] **UI-7** Firmware upload: progress, cancel, task status timeline.
- [ ] **UI-8** KVM: launch/placeholder UX when the console is unsupported.
- [ ] **UI-9** Dashboard: multi-system aggregation, offline/error summaries.
- [ ] **UI-10** Consider stable golden/screenshot smoke tests once layouts settle.

## P2 — refactor and quality

- [ ] **#011** Relocate `ConnectionProfile` to `core`.
- [ ] **#012** Consolidate DI providers.
- [ ] **#013** Remove dead `app_breakpoints.dart`.
- [ ] **#023** Overview: `listenManual` leak and async errors.
- [ ] **#025** Harden unsafe `.first` / `as` casts.
- [ ] Keep coverage **≥ 80%** for every feature touched by a run.
- [ ] Run `dart format` on Dart sources; keep `flutter analyze` at zero.
- [ ] Remove generated/build artifacts from git; keep `.gitignore` current.

## Blocked / needs a human

- [!] **Live BMC integration** — requires real credentials/network; never attempt
      in the unattended job. Keep the live-BMC test skipped.
- [!] **KVM webview/native console** — may require a platform plugin and manual
      device validation; document the decision before adding dependencies.
- [!] **Large spec/binary assets** — if over the download budget, ask a human
      before committing; store links and hashes meanwhile.

---

## Run history pointers

- `automation-tracking.md` — one section per automation run.
- `progress/journal.md` — project daily journal (append-only).
- `progress/progress_summary.md` — weekly rollup.
- `issues/issues.py list --all` — detailed issue queue.
