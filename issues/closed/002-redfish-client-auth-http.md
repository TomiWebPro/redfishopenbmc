---
id: "002"
title: "Redfish client core — HTTP, TLS, auth & session management"
status: closed
priority: P1
type: feature
created: 2026-08-26
updated: 2026-08-27
closed: 2026-08-27
assignee: unassigned
labels: [redfish, client, http, auth, security, openbmc]
estimated_tokens: 45000
---
# 002 — Redfish client core — HTTP, TLS, auth & session management

> Build the low-level Redfish HTTP client: TLS-first `Dio`/`http`, Basic Auth + `SessionService` token auth, per-system session isolation, refresh, and secure error handling.

## Description

Every feature (#003–#009) depends on a trustworthy transport. The Redfish spec supports both Basic Auth and token auth via `POST /redfish/v1/SessionService/Sessions`. OpenBMC's `bmcweb` implements both but prefers sessions. The app must handle both, isolate tokens per BMC, never persist plaintext passwords, and be TLS-first.

- Goal reference: `goal.md` §3.6 Account & Session Management, § Security Requirements, § Architecture → Redfish Client Layer
- User story: As a user I can add a BMC by IP:port + credentials and have the app authenticate securely (Basic or token), isolate that session from other systems, and refresh/expire it gracefully.
- Scope IN: `RedfishClient` class, `AuthManager`, `Session` model, `Dio` interceptors, TLS config, credential storage via `flutter_secure_storage` (behind an interface for tests), error taxonomy, retry/refresh, unit tests with mocked server
- Scope OUT: Discovery traversal (→ #003), multi-system orchestration UI (→ #004), concrete resource models beyond `ServiceRoot` + `Session`

## Goals / Acceptance Criteria

- [x] `lib/redfish/client/redfish_client.dart` — thin wrapper around `Dio`: baseUrl `https://{host}:{port}`, default headers `Accept: application/json`, `OData-Version: 4.0`, 10s connect / 30s receive timeouts, TLS validation on by default with opt-in self-signed toggle per profile
- [x] `lib/redfish/client/auth_manager.dart` — supports `Basic` (base64 header, no persistence) and `Session` (POST `/SessionService/Sessions` with `{UserName,Password}`, captures `X-Auth-Token` + `Location`, stores only token via `SecureStorage`, refresh on 401, `DELETE` on logout)
- [x] Per-system isolation: `Map<systemId, Session>` — token for `bmc1` never sent to `bmc2`
- [x] No plaintext password at rest: passwords only in memory for session creation; `SecureStorage` holds tokens, optional `Password` encrypted if user opts "remember" (document tradeoff)
- [x] Errors normalized: `RedfishException` with `statusCode`, `errorCode` (e.g. `Base.1.8 GeneralError`), `message`, `retryable` — covers 401, 403, 404, 429, 5xx, network, cert
- [x] Interceptor handles 401 → single retry after `DELETE` + re-`POST` session (avoid storm with lock)
- [x] Tests: `test/redfish/client/auth_manager_test.dart` — mocked `Dio`/`http_mock_adapter` for: Basic success, Session create/refresh/logout, 401 retry, cert error, per-system isolation
- [x] ≥80% line coverage on `redfish/client/` (measured 89.4%)
- [x] Docs: `progress/journal.md` + `DEVELOPMENT.md` security notes (TLS, storage backend per platform)

## Tasks

- [x] Define `lib/redfish/models/session.dart` + `lib/redfish/models/redfish_error.dart` (`freezed`/`json_serializable` or plain)
- [x] Implement `SecureStorage` interface `lib/core/storage/secure_storage.dart` + `InMemoryStorage` for tests + `FlutterSecureStorageImpl`
- [x] Implement `RedfishClient` with `Dio` + interceptors + `createDioForProfile(profile)` factory
- [x] Implement `AuthManager.login()` / `logout()` / `withAuth()` + 401 interceptor
- [x] Mock server in tests (use `http_mock_adapter` or `dio_mock`); write 5+ unit tests
- [x] Add integration stub `test/redfish/client/client_integration_test.dart` tagged `integration` (skipped in CI, runs against real OpenBMC if env vars set)
- [x] Update `issues/README.md` example if needed + `progress/journal.md`

## Redfish Mapping

| Feature | Endpoint | Method | Schema / Notes |
|---------|----------|--------|----------------|
| Service root | `/redfish/v1/` | `GET` | `ServiceRoot.v1_15_0` — contains `SessionService.@odata.id` |
| Session login | `/redfish/v1/SessionService/Sessions` | `POST` | `{UserName,Password}` → `201` + `X-Auth-Token` + `Location` |
| Session delete | `/redfish/v1/SessionService/Sessions/{id}` | `DELETE` | requires `X-Auth-Token` |
| SessionService | `/redfish/v1/SessionService` | `GET` | `SessionService.v1_3_0` — `SessionTimeout`, `ServiceEnabled` |
| Auth check | any | `GET` + `Authorization` | `Basic <b64>` or `X-Auth-Token: <token>` |

- OpenBMC `bmcweb` nuance: `X-Auth-Token` header (not `Authorization: Bearer`); limit 16 concurrent sessions by default
- OData traversal: N/A (handled in #003)
- Caching: token cached in memory + secure storage, TTL `SessionTimeout` (seconds)

## Progress Log

- 2026-08-26 — Created. Blocked by #001; blocks #003–#010.
- 2026-08-27 — Core implementation present (RedfishClient, AuthManager, Session, ConnectionProfile, RedfishException, RedfishError, SecureStorage, http_client_config*). Verified `flutter analyze` → 0 issues, `flutter test` → 42 passed (1 integration skipped). `redfish/client/` line coverage measured 89.4% (gate 80%). Added `test/redfish/client/http_client_config_test.dart` for the self-signed TLS branch; wired `RedfishError` envelope into `RedfishException.details` (captures `@Message.ExtendedInfo`) and added a regression test. Removed two debug `print` calls that leaked the auth token to stdout (security fix). Added `## Security notes` section to DEVELOPMENT.md (TLS matrix, secret-at-rest rules, storage backend table, error taxonomy). All acceptance criteria checked. Ready to close.
- 2026-08-27 — Added `RedfishClient.createDioForProfile(profile)` static factory (exposes the shared TLS/header/timeout policy without constructing a client) and `AuthManager.withAuth(systemId, action)` convenience wrapper (throws `StateError` when not logged in, runs the action with the authenticated client, inherits the 401-refresh interceptor). Added `test/redfish/client/redfish_client_extra_test.dart` (factory config + withAuth happy/error paths) and `test/redfish/models/models_test.dart` (Session copyWith/isExpired, ConnectionProfile copyWith/baseUrl, RedfishError both-casing parsing). Re-verified: `flutter analyze` 0 issues, `flutter test` **55 passed / 1 skipped**, `redfish/client/` line coverage **89.8%** (gate 80%). Closes #002.

## References

- `documentations/project_goal/goal.md:120-128`, `242-250` (Security)
- DMTF Redfish spec — SessionService: https://www.dmtf.org/sites/default/files/standards/documents/DSP0266_1.19.0.pdf
- OpenBMC bmcweb: https://github.com/openbmc/bmcweb/blob/master/redfish-core/lib/session.hpp
- `lib/redfish/client/` (to be created) — see #001 structure
- Related: #001, #003, #004

## Closed Criteria

- Resolution: Redfish client core complete: TLS-first Dio transport, Basic+Session auth, per-system token isolation, normalized RedfishException, 401 refresh lock, secure-storage-only-token persistence, mocked unit + integration tests. flutter analyze 0 issues, flutter test 55 passed/1 skipped, redfish/client coverage 89.8% (gate 80%). Unblocks #003.
- Closed: 2026-08-27


- Resolution: All acceptance criteria met and checked; `flutter analyze` 0 issues, `flutter test` 55 passed / 1 skipped, `redfish/client/` coverage 89.8% (≥80%).
- Closed reason: Redfish client core — TLS-first Dio transport, Basic + Session auth, per-system token isolation, normalized `RedfishException`, 401 refresh lock, secure-storage-only-token persistence, and mocked unit/integration tests — is complete and green.
- Follow-ups: #010 will add the security regression gate (`token_isolation_test`, `no_plaintext_test`, TLS enforcement tests) re-using the #002 primitives; discovery (#003) and all feature issues now unblocked.
