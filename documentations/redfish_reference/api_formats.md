# Redfish API Formats — Quick Reference

Consolidated endpoint + critical-field reference for the resources our Flutter app consumes.
All URIs, field names, and types below are taken directly from the DMTF `public-rackmount1`
mockup and the DMTF JSON schemas. Types are the resolved schema types (versioned definitions).

Legend: `obj` = object, `arr` = array, `ref` = `{ "@odata.id": "..." }` link,
`str` = string, `int` = integer, `num` = number, `bool` = boolean.

---

## ComputerSystem
- **Collection:** `GET /redfish/v1/Systems`  → `Members` (arr of ref), `Members@odata.count` (int)
- **Member:** `GET /redfish/v1/Systems/{id}`
- **Critical fields:**
  | Field | Type | Notes |
  |---|---|---|
  | `Id` | str | Resource id (e.g. `437XR1138R2`) |
  | `Name` | str | Display name |
  | `SystemType` | str enum | `Physical` / `Virtual` / `OS` / ... |
  | `PowerState` | str enum | `On` / `Off` / `PoweringOn` / ... |
  | `Status` | obj | `{ State, Health, HealthRollup }` |
  | `Manufacturer` / `Model` / `SerialNumber` / `PartNumber` / `SKU` | str | Inventory identifiers |
  | `UUID` | str | System UUID |
  | `HostName` | str | OS hostname |
  | `BiosVersion` | str | Current BIOS version |
  | `ProcessorSummary` / `MemorySummary` | obj | Count + health rollups |
  | `Processors` / `Memory` / `EthernetInterfaces` / `Storage` | ref (collection links) | Sub-resources |
  | `Boot` | obj | `BootSourceOverrideTarget`, `BootSourceOverrideEnabled`, `BootSourceOverrideMode` |
  | `IndicatorLED` | str enum | `Lit` / `Off` / `Blinking` |
  | `PowerRestorePolicy` | str enum | `AlwaysOn` / `AlwaysOff` / `LastState` |
  | `Actions` | obj | `#ComputerSystem.Reset` (target `/redfish/v1/Systems/{id}/Actions/ComputerSystem.Reset`, body `{ "ResetType": "GracefulRestart" }`) |

---

## Chassis
- **Collection:** `GET /redfish/v1/Chassis`
- **Member:** `GET /redfish/v1/Chassis/{id}`
- **Critical fields:**
  | Field | Type | Notes |
  |---|---|---|
  | `Id` / `Name` | str | e.g. `1U` |
  | `ChassisType` | str enum | `Rack` / `Blade` / `Enclosure` / `Board` / ... |
  | `Status` | obj | health/state |
  | `Manufacturer` / `Model` / `SerialNumber` / `PartNumber` / `AssetTag` | str | |
  | `PowerState` | str enum | `On` / `Off` |
  | `Thermal` / `Power` | ref | sub-resources (`/Chassis/{id}/Thermal`, `/Power`) |
  | `Sensors` | ref | `/Chassis/{id}/Sensors` (SensorCollection) |
  | `PhysicalSecurity` / `Location` / `EnvironmentalClass` | obj | optional |

---

## Manager (BMC)
- **Collection:** `GET /redfish/v1/Managers`
- **Member:** `GET /redfish/v1/Managers/{id}` (e.g. `BMC`)
- **Critical fields:**
  | Field | Type | Notes |
  |---|---|---|
  | `Id` / `Name` | str | `BMC` |
  | `ManagerType` | str enum | `BMC` / `EnclosureManager` / `ManagementController` |
  | `Status` | obj | |
  | `FirmwareVersion` | str | BMC firmware |
  | `Model` / `Manufacturer` / `SerialNumber` | str | |
  | `UUID` | str | |
  | `GraphicalConsole` / `SerialConsole` / `CommandShell` | obj | `{ ConnectTypesSupported, MaxConcurrentSessions, Enabled }` |
  | `NetworkProtocol` | ref | `/Managers/{id}/NetworkProtocol` |
  | `EthernetInterfaces` | ref | collection of EthernetInterface |
  | `LogServices` | ref | collection of LogService |
  | `HostInterfaces` / `SerialInterfaces` | ref | |
  | `Actions` | obj | `#Manager.Reset`, `#Manager.ImportConfiguration` |

---

## Power (under Chassis)
- **URI:** `GET /redfish/v1/Chassis/{id}/Power`
- **Critical fields:**
  | Field | Type | Notes |
  |---|---|---|
  | `PowerSupplies` | arr of obj | each: `MemberId` (str), `Name`, `Status`, `PowerSupplyType` (str enum: `AC`/`DC`), `LineInputVoltage` (num), `PowerOutputWatts` (num), `LastPowerOutputWatts` (num), `InputRanges` (arr), `Redundancy` (ref arr), `HotPluggable` (bool), `FaultDetected` (bool) |
  | `PowerControl` | arr of obj | each: `MemberId`, `Name`, `PowerConsumedWatts` (num), `PowerRequestedWatts` (num), `PowerLimit` (obj: `LimitInWatts`), `PowerMetrics` (obj: `AverageConsumedWatts`, `MaxConsumedWatts`, `MinConsumedWatts`) |
  | `Redundancy` | arr of obj | `{ Mode, RedundancyEnabled, Status, MinNumNeeded }` |
  | `PowerRestorePolicy` | str enum | |
  | `Status` | obj | |

---

## Thermal (under Chassis)
- **URI:** `GET /redfish/v1/Chassis/{id}/Thermal`
- **Critical fields:**
  | Field | Type | Notes |
  |---|---|---|
  | `Temperatures` | arr of obj | each: `MemberId`, `Name`, `ReadingCelsius` (num), `MinReadingRangeTemp` (num), `MaxReadingRangeTemp` (num), `PhysicalContext` (str), `Status`, `UpperThresholdCritical`/`LowerThresholdCritical` (num, optional) |
  | `Fans` | arr of obj | each: `MemberId`, `Name`, `Reading` (num, RPM), `ReadingUnits` (str, e.g. `RPM`), `PhysicalContext` (str), `Status`, `UpperThresholdCritical` (num, optional), `Redundancy` (ref arr) |
  | `Redundancy` | arr of obj | fan/power redundancy sets |
  | `Status` | obj | |

---

## Sensor (under Chassis/{id}/Sensors)
- **Collection:** `GET /redfish/v1/Chassis/{id}/Sensors`
- **Member:** `GET /redfish/v1/Chassis/{id}/Sensors/{sensorId}`
- **Critical fields:**
  | Field | Type | Notes |
  |---|---|---|
  | `Id` / `Name` | str | e.g. `FanBay2`, `TotalPower` |
  | `Reading` | num | current value |
  | `ReadingType` | str enum | `Temperature` / `Fan` / `Voltage` / `Current` / `Power` / `Energy` / `Percent` / `Frequency` / ... |
  | `ReadingUnits` | str | unit text (`C`, `%`, `W`, `V`, `A`, `RPM`, ...) |
  | `ReadingRangeMin` / `ReadingRangeMax` | num | |
  | `PhysicalContext` | str enum | `Chassis` / `CPU` / `DIMM` / `PowerSupply` / ... |
  | `Status` | obj | |
  | `Thresholds` | obj | `{ LowerCaution/LowerCritical/UpperCaution/UpperCritical: { Reading: num, DwellTime: str } }` |
  | `ValueAccuracy` / `Calibration` | num / obj | optional |

---

## UpdateService
- **URI:** `GET /redfish/v1/UpdateService`
- **Critical fields:**
  | Field | Type | Notes |
  |---|---|---|
  | `ServiceEnabled` | bool | |
  | `HttpPushUri` | str | upload target for firmware images |
  | `HttpPushUriOptions` / `HttpPushUriOptionsBusy` | obj / bool | |
  | `FirmwareInventory` | ref | `/redfish/v1/UpdateService/FirmwareInventory` (collection of SoftwareInventory) |
  | `SoftwareInventory` | ref | (same shape; not present in this mockup) |
  | `ClientCertificates` | ref | |
  | `Actions` | obj | `#UpdateService.SimpleUpdate` → target `/redfish/v1/UpdateService/Actions/SimpleUpdate`; body `{ "ImageURI": str, "TransferProtocol": "HTTPS"/"TFTP"/..., "Targets": arr, "@Redfish.OperationApplyTime": str }`. `#UpdateService.StartUpdate` may also exist. |
- **Note:** firmware inventory members are `SoftwareInventory` resources (see below).

---

## SoftwareInventory (FirmwareInventory member)
- **Collection:** `GET /redfish/v1/UpdateService/FirmwareInventory`
- **Member:** `GET /redfish/v1/UpdateService/FirmwareInventory/{id}` (e.g. `BMC`, `BIOS`, `SS`)
- **Critical fields:**
  | Field | Type | Notes |
  |---|---|---|
  | `Id` / `Name` | str | |
  | `Version` | str | firmware/software version |
  | `SoftwareId` | str | |
  | `Status` | obj | |
  | `Updatable` | bool | whether SimpleUpdate can target it |
  | `Updateable` | bool | (legacy spelling) |
  | `Manufacturer` / `ReleaseDate` / `BuildNumber` / `MinorVersion` / `Revision` / `SparePartNumber` | str | |
  | `RelatedItem` | arr of ref | links to Chassis/System the inventory belongs to |
  | `LowestSupportedVersion` | str | |

---

## AccountService
- **URI:** `GET /redfish/v1/AccountService`
- **Critical fields:**
  | Field | Type | Notes |
  |---|---|---|
  | `Accounts` | ref | `/redfish/v1/AccountService/Accounts` (collection) |
  | `Roles` | ref | `/redfish/v1/AccountService/Roles` |
  | `AccountLockoutThreshold` / `AccountLockoutDuration` / `AccountLockoutCounterResetAfter` | int | lockout policy |
  | `MinPasswordLength` / `MaxPasswordLength` | int | |
  | `LDAP` / `ActiveDirectory` / `TACACSplus` / `Radius` | obj | external auth config |
  | `ExternalAccountProviders` | ref | |
- **Account member:** `GET/POST/DELETE /redfish/v1/AccountService/Accounts/{id}` — fields: `Id`, `Name`, `UserName` (str), `Password` (write-only str), `RoleId` (str, ref to Roles), `Enabled` (bool), `Locked` (bool), `Status`.

---

## SessionService
- **URI:** `GET /redfish/v1/SessionService`
- **Critical fields:**
  | Field | Type | Notes |
  |---|---|---|
  | `SessionTimeout` | int | seconds |
  | `Sessions` | ref | `/redfish/v1/SessionService/Sessions` |
  | `Actions` | obj | `#SessionService.OverrideToken` (optional) |
- **Login:** `POST /redfish/v1/SessionService/Sessions` with body `{ "UserName": str, "Password": str }`;
  response sets `X-Auth-Token` header and returns the new session `@odata.id`.
- **Logout:** `DELETE /redfish/v1/SessionService/Sessions/{id}`.

---

## EthernetInterface
- **Collection:** `GET /redfish/v1/Managers/{id}/EthernetInterfaces` (and under Systems)
- **Member:** `GET /redfish/v1/Managers/{id}/EthernetInterfaces/{ifaceId}` (e.g. `eth0`)
- **Critical fields:**
  | Field | Type | Notes |
  |---|---|---|
  | `Id` / `Name` | str | `eth0` |
  | `MACAddress` | str | |
  | `Status` | obj | |
  | `LinkStatus` | str enum | `LinkUp` / `LinkDown` / `NoLink` |
  | `InterfaceEnabled` | bool | |
  | `IPv4Addresses` | arr of obj | `{ Address, SubnetMask, AddressOrigin (DHCP/Static), Gateway }` |
  | `IPv6Addresses` | arr of obj | `{ Address, PrefixLength, AddressOrigin, Gateway }` |
  | `IPv4StaticAddresses` / `IPv6StaticAddresses` | arr of obj | |
  | `DHCPv4` / `DHCPv6` | obj | `{ DHCPEnabled: bool }` |
  | `VLAN` | obj | `{ VLANEnabled: bool, VLANId: int }` |
  | `HostName` / `FQDN` | str | |
  | `NameServers` | arr of str | |

---

## EventService
- **URI:** `GET /redfish/v1/EventService`
- **Critical fields:**
  | Field | Type | Notes |
  |---|---|---|
  | `Subscriptions` | ref | `/redfish/v1/EventService/Subscriptions` |
  | `ServerSentEventUri` | str | SSE stream URI (optional) |
  | `DeliveryRetryAttempts` / `DeliveryRetryIntervalSeconds` | int | |
  | `EventTypesForTelemetry` | arr of str | |
  | `Actions` | obj | `#EventService.SubmitTestEvent`, `#EventService.CreateSubscription` (optional) |
- **Subscribe:** `POST /redfish/v1/EventService/Subscriptions` with body
  `{ "Destination": str (callback URI), "EventTypes": arr, "Context": str, "Protocol": "Redfish" }`.

---

## LogService
- **URI:** `GET /redfish/v1/Managers/{id}/LogServices/{logId}` (also under Systems)
  - e.g. `/redfish/v1/Managers/BMC/LogServices/Log`
- **Critical fields:**
  | Field | Type | Notes |
  |---|---|---|
  | `Id` / `Name` | str | `Log` |
  | `Status` | obj | |
  | `Entries` | ref | `/.../LogServices/{logId}/Entries` (collection) |
  | `OverWritePolicy` | str enum | `WrapsWhenFull` / `NeverOverWrites` / ... |
  | `MaxNumberOfRecords` | int | |
  | `DateTime` / `DateTimeLocalOffset` | str | |
  | `Actions` | obj | `#LogService.ClearLog`, `#LogService.CollectLog` (optional) |
- **Log entry member:** `GET /.../Entries/{id}` — fields: `Id` (str), `Message` (str),
  `MessageId` (str, e.g. `BMC.1.0.Event`), `Severity` (str: `OK`/`Warning`/`Critical`),
  `Created` (date-time str), `EntryType` (str), `SensorNumber` (int, optional), `Oem` (obj).

---

## RedfishError (error responses)
Returned on any non-2xx. Body:
```json
{
  "error": {
    "code": "Base.1.0.GeneralError",
    "message": "An error has occurred. See ExtendedInfo for more information.",
    "@Message.ExtendedInfo": [
      { "MessageId": "Base.1.0.GeneralError", "Message": "...", "Severity": "Critical", "Resolution": "None" }
    ]
  }
}
```
- `code` / `message` are strings; `@Message.ExtendedInfo` is an array of message objects keyed by `MessageId`
  (lookup in the Redfish Message Registry). See [redfish_error.md](redfish_error.md).
