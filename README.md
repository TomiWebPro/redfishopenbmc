# redfishopenbmc

Redfish/OpenBMC multi-server control Flutter app

A schema-driven, cross-platform Flutter application providing a unified control plane for managing servers through the Redfish API, including OpenBMC-based systems. The app connects to multiple BMCs, authenticates securely, and dynamically discovers each system's capabilities by traversing the `/redfish/v1/` resource tree — rendering only features the device actually supports.

## Core capabilities

- Multi-system management with connection profiles and unified dashboard
- Power control (ON/OFF/restart/reset) via `ComputerSystem.Reset`
- System overview: power state, health, manufacturer/model, CPU/memory, temperatures
- Remote KVM (HTML5/embedded console) where supported
- Real-time sensor monitoring (temps, fans, voltages) with threshold alerts
- Firmware update management and update-job monitoring
- Secure credential storage via platform keystore

## Design philosophy

*"Everything is discovered, nothing is assumed"* — the UI is always a reflection of the Redfish schema, never hardcoded. Mobile, tablet, and desktop adaptive layouts.

## Status

[![verify](https://github.com/TomiWebPro/redfishopenbmc/actions/workflows/verify.yml/badge.svg)](https://github.com/TomiWebPro/redfishopenbmc/actions/workflows/verify.yml)

Implementation in progress. Every push to `main` and every pull request runs
the `verify` workflow: `flutter analyze` (0 issues), the full `flutter test`
suite with coverage, and the ≥75% overall / ≥80% scoped line-coverage gate.
See [DEVELOPMENT.md](DEVELOPMENT.md#testing--coverage-gate-issue-010) for the
local commands and current coverage numbers.

## License

MIT License with Geographic Use Restriction Addendum (MIT + GURAv1) — see [LICENSE](LICENSE).
