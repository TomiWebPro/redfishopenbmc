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

Planning phase — complete architecture/end-goal specification defined, no implementation yet.

## License

MIT License with Geographic Use Restriction Addendum (MIT + GURAv1) — see [LICENSE](LICENSE).
