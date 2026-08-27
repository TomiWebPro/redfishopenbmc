# Manager

Represents a management controller (the BMC itself). Top resource under /redfish/v1/Managers.

**Schema definition:** `Manager`  

**Example source (DMTF mockup):** `Managers/BMC/index.json`


## Example payload

```json
{
  "@odata.type": "#Manager.v1_19_0.Manager",
  "Id": "BMC",
  "Name": "Manager",
  "ManagerType": "BMC",
  "Description": "Contoso BMC",
  "ServiceEntryPointUUID": "92384634-2938-2342-8820-489239905423",
  "UUID": "58893887-8974-2487-2389-841168418919",
  "Model": "Joo Janta 200",
  "DateTime": "2015-03-13T04:14:33+06:00",
  "DateTimeLocalOffset": "+06:00",
  "Status": {
    "State": "Enabled",
    "Health": "OK"
  },
  "PowerState": "On",
  "GraphicalConsole": {
    "ServiceEnabled": true,
    "MaxConcurrentSessions": 2,
    "ConnectTypesSupported": [
      "KVMIP"
    ]
  },
  "SerialConsole": {
    "ServiceEnabled": true,
    "MaxConcurrentSessions": 1,
    "ConnectTypesSupported": [
      "Telnet",
      "SSH"
    ]
  },
  "CommandShell": {
    "ServiceEnabled": true,
    "MaxConcurrentSessions": 4,
    "ConnectTypesSupported": [
      "Telnet",
      "SSH"
    ]
  },
  "FirmwareVersion": "1.45.455b66-rev4",
  "AdditionalFirmwareVersions": {
    "Bootloader": "v2022.01",
    "Kernel": "Linux 5.13.0-30-generic arm71",
    "Oem": {
      "Contoso": {
        "@odata.type": "#ContosoSoftwareInventory.v1_0_0.AdditionalVersions",
        "ManagementApp": "1.30"
      }
    }
  },
  "NetworkProtocol": {
    "@odata.id": "/redfish/v1/Managers/BMC/NetworkProtocol"
  },
  "EthernetInterfaces": {
    "@odata.id": "/redfish/v1/Managers/BMC/EthernetInterfaces"
  },
  "HostInterfaces": {
    "@odata.id": "/redfish/v1/Managers/BMC/HostInterfaces"
  },
  "SerialInterfaces": {
    "@odata.id": "/redfish/v1/Managers/BMC/SerialInterfaces"
  },
  "LogServices": {
    "@odata.id": "/redfish/v1/Managers/BMC/LogServices"
  },
  "DedicatedNetworkPorts": {
    "@odata.id": "/redfish/v1/Managers/BMC/DedicatedNetworkPorts"
  },
  "SecurityPolicy": {
    "@odata.id": "/redfish/v1/Managers/BMC/SecurityPolicy"
  },
  "Links": {
    "ManagerForServers": [
      {
        "@odata.id": "/redfish/v1/Systems/437XR1138R2"
      }
    ],
    "ManagerForChassis": [
      {
        "@odata.id": "/redfish/v1/Chassis/1U"
      }
    ],
    "ManagerInChassis": {
      "@odata.id": "/redfish/v1/Chassis/1U"
    }
  },
  "Actions": {
    "#Manager.Reset": {
      "target": "/redfish/v1/Managers/BMC/Actions/Manager.Reset",
      "ResetType@Redfish.AllowableValues": [
        "ForceRestart",
        "GracefulRestart"
      ]
    }
  },
  "@odata.id": "/redfish/v1/Managers/BMC",
  "@Redfish.Copyright": "Copyright 2014-2023 DMTF. For the full DMTF copyright policy, see http://www.dmtf.org/about/policies/copyright."
}
```


## Properties

| Property | Type | Required | Description |
|---|---|---|---|
| `@odata.context` | context | No | see mockup |
| `@odata.etag` | etag | No | see mockup |
| `@odata.id` | id | Yes | see mockup |
| `@odata.type` | type | Yes | see mockup |
| `Actions` | Actions | No | The available actions for this resource. |
| `AdditionalFirmwareVersions` | AdditionalVersions | No | The additional firmware versions of the manager. |
| `AutoDSTEnabled` | boolean | No | An indication of whether the manager is configured for automatic Daylight Saving Time (DST) adjustment. |
| `Certificates` | CertificateCollection | No | The link to a collection of certificates for device identity and attestation. |
| `CommandShell` | CommandShell | No | The manager's command line user interface or command shell service. |
| `DateTime` | string | No | The current date and time with UTC offset of the manager. |
| `DateTimeLocalOffset` | string | No | The time offset from UTC that the `DateTime` property is in `+HH:MM` format. |
| `DateTimeSource` | DateTimeSource | No | The source of the date and time of this manager, such as NTP, RTC, or firmware. |
| `DaylightSavingTime` | DaylightSavingTime | No | The daylight saving time settings for this manager. |
| `DedicatedNetworkPorts` | PortCollection | No | The dedicated network ports of the manager. |
| `Description` | Description | No | see mockup |
| `EthernetInterfaces` | EthernetInterfaceCollection | No | The link to a collection of NICs that this manager uses for network communication. |
| `FirmwareVersion` | string | No | The firmware version of this manager. |
| `GraphicalConsole` | GraphicalConsole | No | The manager's graphical console service. |
| `HostInterfaces` | HostInterfaceCollection | No | The link to a collection of host interfaces that this manager uses for local host communication. Clients can find host interface configuration options and settings in this navigation property. |
| `Id` | Id | Yes | see mockup |
| `LastResetTime` | string | No | The date and time when the manager was last reset or rebooted. |
| `Links` | Links | No | The links to other resources that are related to this resource. |
| `Location` | Location | No | The location of the manager. |
| `LocationIndicatorActive` | boolean | No | An indicator allowing an operator to physically locate this resource. |
| `LogServices` | LogServiceCollection | No | The link to a collection of logs that the manager uses. |
| `ManagerDiagnosticData` | ManagerDiagnosticData | No | The diagnostic data for this manager. |
| `ManagerType` | ManagerType | No | The type of manager that this resource represents. |
| `Manufacturer` | string | No | The manufacturer of this manager. |
| `Measurements` | array of MeasurementBlock | No | An array of DSP0274-defined measurement blocks. |
| `Model` | string | No | The model information of this manager, as defined by the manufacturer. |
| `Name` | Name | Yes | see mockup |
| `NetworkProtocol` | ManagerNetworkProtocol | No | The link to the network services and their settings that the manager controls. |
| `OEMSecurityMode` | string | No | The OEM-specific security compliance mode(s) that the manager is currently configured to enforce. |
| `Oem` | Oem | No | The OEM extension property. |
| `PartNumber` | string | No | The part number of the manager. |
| `PowerState` | PowerState | No | The current power state of the manager. |
| `ReadyToRemove` | boolean | No | An indication of whether the manager is prepared by the system for removal. |
| `Redundancy` | array of Redundancy | No | The redundancy information for the managers of this system. |
| `Redundancy@odata.count` | count | No | see mockup |
| `RemoteAccountService` | AccountService | No | The link to the account service resource for the remote manager that this resource represents. |
| `RemoteRedfishServiceUri` | string | No | The URI of the Redfish service root for the remote manager that this resource represents. |
| `SecurityMode` | SecurityModeTypes | No | The security compliance mode that the manager is currently configured to enforce. |
| `SecurityPolicy` | SecurityPolicy | No | The security policy settings for this manager. |
| `SerialConsole` | SerialConsole | No | The serial console service that this manager provides. |
| `SerialInterfaces` | SerialInterfaceCollection | No | The link to a collection of serial interfaces that this manager uses for serial and console communication. |
| `SerialNumber` | string | No | The serial number of the manager. |
| `ServiceEntryPointUUID` | UUID | No | The UUID of the Redfish service that is hosted by this manager. |
| `ServiceIdentification` | string | No | A product instance identifier displayed in the Redfish service root. |
| `ServiceUseNotification` | string | No | The usage notification message displayed in the Redfish service root. |
| `SharedNetworkPorts` | PortCollection | No | The shared network ports of the manager. |
| `SparePartNumber` | string | No | The spare part number of the manager. |
| `Status` | Status | No | The status and health of the resource and its subordinate or dependent resources. |
| `TimeZoneName` | string | No | The time zone of the manager. |
| `USBPorts` | PortCollection | No | The USB ports of the manager. |
| `UUID` | UUID | No | The UUID for this manager. |
| `Version` | string | No | The hardware version of this manager. |
| `VirtualMedia` | VirtualMediaCollection | No | The link to the virtual media services for this particular manager. |

