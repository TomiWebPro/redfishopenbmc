# Redfish Data Model — Overview

Redfish is a RESTful management API for server hardware. All responses are JSON and
every resource carries Redfish/OData metadata (`@odata.id`, `@odata.type`, `@odata.context`).

This reference is grounded in the **DMTF `public-rackmount1` mockup** (Redfish v1.15.0),
so every example and field type below is real, not invented.

## Resource hierarchy

```
/redfish/v1/                       ServiceRoot  (index.json)
├── Systems                        ComputerSystemCollection
│   └── {id}                       ComputerSystem   (Processors, Memory, EthernetInterfaces,
│                                                  LogServices, Bios, SecureBoot, VirtualMedia...)
├── Chassis                        ChassisCollection
│   └── {id}                       Chassis
│       ├── Power                  Power           (PowerSupplies, Redundancy, PowerControl)
│       ├── Thermal                Thermal         (Fans, Temperatures, Redundancy)
│       └── Sensors                SensorCollection
│           └── {id}               Sensor          (single reading)
├── Managers                       ManagerCollection
│   └── {id}                       Manager (BMC)   (EthernetInterfaces, NetworkProtocol,
│                                                  LogServices, HostInterfaces, SerialInterfaces)
├── UpdateService                  UpdateService   (SimpleUpdate action, FirmwareInventory,
│                                                  SoftwareInventory, ClientCertificates)
├── AccountService                 AccountService  (Accounts, Roles, ExternalAccountProviders)
├── SessionService                 SessionService  (Sessions — POST to log in)
├── EventService                   EventService    (Subscriptions — push alerts)
├── TaskService                    TaskService     (Tasks)
├── CertificateService             CertificateService
├── KeyService                     KeyService
├── ComponentIntegrity             ComponentIntegrity
└── Registries / odata / $metadata  (schema/registry metadata)
```

All collections share the same shape: an object with `Members` (array of `@odata.id`
references), `Members@odata.count`, `Name`, and the standard OData annotations.

## Common conventions
- **Identifiers** are in `Id` (resource id) and the canonical path is `@odata.id`.
- **Health/state** is reported via a `Status` object: `{ "State": "Enabled", "Health": "OK" }`.
- **Actions** appear under an `Actions` object, e.g.
  `#UpdateService.SimpleUpdate` with a `target` URI.
- **OEM extensions** live under `Oem` (OpenBMC-specific data is often here).
- **Links to other resources** are objects of the form `{ "@odata.id": "/redfish/v1/..." }`.

## Table of contents
- [ComputerSystem](computer_system.md)
- [Chassis](chassis.md)
- [Manager](manager.md)
- [Power](power.md)
- [Thermal](thermal.md)
- [Sensor](sensor.md)
- [UpdateService](update_service.md)
- [SoftwareInventory](software_inventory.md)
- [AccountService](account_service.md)
- [SessionService](session_service.md)
- [EthernetInterface](ethernet_interface.md)
- [EventService](event_service.md)
- [LogService](log_service.md)
- [RedfishError](redfish_error.md)

For a consolidated endpoint + field cheat-sheet, see [api_formats.md](api_formats.md).
