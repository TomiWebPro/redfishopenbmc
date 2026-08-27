# ComputerSystem

Represents a computing system (a server, blade, or host) managed by the BMC. The top resource under /redfish/v1/Systems.

**Schema definition:** `ComputerSystem`  

**Example source (DMTF mockup):** `Systems/437XR1138R2/index.json`


## Example payload

```json
{
  "@odata.type": "#ComputerSystem.v1_22_0.ComputerSystem",
  "Id": "437XR1138R2",
  "Name": "WebFrontEnd483",
  "SystemType": "Physical",
  "AssetTag": "Chicago-45Z-2381",
  "Manufacturer": "Contoso",
  "Model": "3500",
  "SubModel": "RX",
  "SKU": "8675309",
  "SerialNumber": "437XR1138R2",
  "PartNumber": "224071-J23",
  "Description": "Web Front End node",
  "UUID": "38947555-7742-3448-3784-823347823834",
  "HostName": "web483",
  "Status": {
    "State": "Enabled",
    "Health": "OK",
    "HealthRollup": "OK"
  },
  "HostingRoles": [
    "ApplicationServer"
  ],
  "IndicatorLED": "Off",
  "PowerState": "On",
  "Boot": {
    "BootSourceOverrideEnabled": "Once",
    "BootSourceOverrideTarget": "Pxe",
    "BootSourceOverrideTarget@Redfish.AllowableValues": [
      "None",
      "Pxe"
    ],
    "BootSourceOverrideMode": "UEFI",
    "UefiTargetBootSourceOverride": "/0x31/0x33/0x01/0x01"
  },
  "TrustedModules": [
    {
      "FirmwareVersion": "1.13b",
      "InterfaceType": "TPM1_2",
      "Status": {
        "State": "Enabled",
        "Health": "OK"
      }
    }
  ],
  "Oem": {
    "Contoso": {
      "@odata.type": "#Contoso.ComputerSystem",
      "ProductionLocation": {
        "FacilityName": "PacWest Production Facility",
        "Country": "USA"
      }
    },
    "Chipwise": {
      "@odata.type": "#Chipwise.ComputerSystem",
      "Style": "Executive"
    }
  },
  "BootProgress": {
    "LastState": "OSRunning",
    "LastStateTime": "2021-03-13T04:14:13+06:00",
    "LastBootTimeSeconds": 676
  },
  "LastResetTime": "2021-03-13T04:02:57+06:00",
  "BiosVersion": "P79 v1.45 (12/06/2017)",
  "ProcessorSummary": {
    "Count": 2,
    "Model": "Multi-Core Intel(R) Xeon(R) processor 7xxx Series",
    "LogicalProcessorCount": 16,
    "CoreCount": 8,
    "Status": {
      "State": "Enabled",
      "Health": "OK",
      "HealthRollup": "OK"
    }
  },
  "MemorySummary": {
    "TotalSystemMemoryGiB": 96,
    "TotalSystemPersistentMemoryGiB": 0,
    "MemoryMirroring": "None",
    "Status": {
      "State": "Enabled",
      "Health": "OK",
      "HealthRollup": "OK"
    }
  },
  "Bios": {
    "@odata.id": "/redfish/v1/Systems/437XR1138R2/Bios"
  },
  "SecureBoot": {
    "@odata.id": "/redfish/v1/Systems/437XR1138R2/SecureBoot"
  },
  "Processors": {
    "@odata.id": "/redfish/v1/Systems/437XR1138R2/Processors"
  },
  "Memory": {
    "@odata.id": "/redfish/v1/Systems/437XR1138R2/Memory"
  },
  "EthernetInterfaces": {
    "@odata.id": "/redfish/v1/Systems/437XR1138R2/EthernetInterfaces"
  },
  "SimpleStorage": {
    "@odata.id": "/redfish/v1/Systems/437XR1138R2/SimpleStorage"
  },
  "LogServices": {
    "@odata.id": "/redfish/v1/Systems/437XR1138R2/LogServices"
  },
  "GraphicsControllers": {
    "@odata.id": "/redfish/v1/Systems/437XR1138R2/GraphicsControllers"
  },
  "USBControllers": {
    "@odata.id": "/redfish/v1/Systems/437XR1138R2/USBControllers"
  },
  "Certificates": {
    "@odata.id": "/redfish/v1/Systems/437XR1138R2/Certificates"
  },
  "VirtualMedia": {
    "@odata.id": "/redfish/v1/Systems/437XR1138R2/VirtualMedia"
  },
  "Links": {
    "Chassis": [
      {
        "@odata.id": "/redfish/v1/Chassis/1U"
      }
    ],
    "ManagedBy": [
      {
        "@odata.id": "/redfish/v1/Managers/BMC"
      }
    ]
  },
  "Actions": {
    "#ComputerSystem.Reset": {
      "target": "/redfish/v1/Systems/437XR1138R2/Actions/ComputerSystem.Reset",
      "ResetType@Redfish.AllowableValues": [
        "On",
        "ForceOff"
      ]
    },
    "Oem": {
      "#Contoso.Reset": {
        "target": "/redfish/v1/Systems/437XR1138R2/Oem/Contoso/Actions/Contoso.Reset"
      }
    }
  },
  "@odata.id": "/redfish/v1/Systems/437XR1138R2",
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
| `AssetTag` | string | No | The user-definable tag that can track this computer system for inventory or other client purposes. |
| `Bios` | Bios | No | The link to the BIOS settings associated with this system. |
| `BiosVersion` | string | No | The version of the system BIOS or primary system firmware. |
| `Boot` | Boot | No | The boot settings for this system. |
| `BootImagePushURI` | string | No | The URI used to perform a Redfish Specification-defined multipart HTTP or HTTPS push upload, configuration, and immediate boot from a virtual media image. |
| `BootProgress` | BootProgress | No | This object describes the last boot progress state. |
| `Certificates` | CertificateCollection | No | The link to a collection of certificates for device identity and attestation. |
| `Composition` | Composition | No | Information about the composition capabilities and state of the computer system. |
| `Description` | Description | No | see mockup |
| `EthernetInterfaces` | EthernetInterfaceCollection | No | The link to the collection of Ethernet interfaces associated with this system. |
| `FabricAdapters` | FabricAdapterCollection | No | The link to the collection of fabric adapters associated with this system. |
| `GraphicalConsole` | HostGraphicalConsole | No | The information about the graphical console (KVM-IP) service of this system. |
| `GraphicsControllers` | GraphicsControllerCollection | No | The link to a collection of graphics controllers that can output video for this system. |
| `HostName` | string | No | The DNS host name, without any domain information. |
| `HostWatchdogTimer` | WatchdogTimer | No | The host watchdog timer functionality for this system. |
| `HostedServices` | HostedServices | No | The services that this computer system supports. |
| `HostingRoles` | array of HostingRole | No | The hosting roles that this computer system supports. |
| `IPMIHostInterface` | IPMIHostInterface | No | The information about the in-band IPMI service of this system. |
| `Id` | Id | Yes | see mockup |
| `IdlePowerSaver` | IdlePowerSaver | No | The idle power saver settings of the computer system. |
| `IndicatorLED` | IndicatorLED | No | The state of the indicator LED, which identifies the system. |
| `KeyManagement` | KeyManagement | No | The key management settings of the computer system. |
| `LastResetCause` | LastResetCauses | No | The last reset cause of the system. |
| `LastResetTime` | string | No | The date and time when the system was last reset or rebooted. |
| `Links` | Links | No | The links to other resources that are related to this resource. |
| `LocationIndicatorActive` | boolean | No | An indicator allowing an operator to physically locate this resource. |
| `LogServices` | LogServiceCollection | No | The link to the collection of log services associated with this system. |
| `Manufacturer` | string | No | The manufacturer or OEM of this system. |
| `ManufacturingMode` | boolean | No | An indication of whether the system is in manufacturing mode. Manufacturing mode is a special boot mode, not normally available to end users, that modifies features and settings for use while the system is being manuf... |
| `Measurements` | array of MeasurementBlock | No | An array of DSP0274-defined measurement blocks. |
| `Memory` | MemoryCollection | No | The link to the collection of memory associated with this system. |
| `MemoryDomains` | MemoryDomainCollection | No | The link to the collection of memory domains associated with this system. |
| `MemorySummary` | MemorySummary | No | The central memory of the system in general detail. |
| `Model` | string | No | The product name for this system, without the manufacturer name. |
| `MultipartImportConfigurationPushURI` | string | No | The URI used to perform a Redfish Specification-defined multipart HTTP or HTTPS push import of a vendor-specific configuration file. |
| `Name` | Name | Yes | see mockup |
| `NetworkInterfaces` | NetworkInterfaceCollection | No | The link to the collection of Network Interfaces associated with this system. |
| `Oem` | Oem | No | The OEM extension property. |
| `OperatingSystem` | OperatingSystem | No | The link to the operating system information associated with this system. |
| `PCIeDevices` | array of PCIeDevice | No | The link to a collection of PCIe devices that this computer system uses. |
| `PCIeDevices@odata.count` | count | No | see mockup |
| `PCIeFunctions` | array of PCIeFunction | No | The link to a collection of PCIe functions that this computer system uses. |
| `PCIeFunctions@odata.count` | count | No | see mockup |
| `PartNumber` | string | No | The part number for this system. |
| `PowerCycleDelaySeconds` | number | No | The number of seconds to delay power on after a `Reset` action requesting `PowerCycle` or `FullPowerCycle`. Zero seconds indicates no delay. |
| `PowerMode` | PowerMode | No | The power mode setting of the computer system. |
| `PowerOffDelaySeconds` | number | No | The number of seconds to delay power off during a reset. Zero seconds indicates no delay to power off. |
| `PowerOnDelaySeconds` | number | No | The number of seconds to delay power on after an externally performed power cycle or during a reset. Zero seconds indicates no delay to power up. |
| `PowerRestorePolicy` | PowerRestorePolicyTypes | No | The desired power state of the system when power is restored after a power loss. |
| `PowerState` | PowerState | No | The current power state of the system. |
| `ProcessorSummary` | ProcessorSummary | No | The central processors of the system in general detail. |
| `Processors` | ProcessorCollection | No | The link to the collection of processors associated with this system. |
| `Redundancy` | array of Redundancy | No | The link to a collection of redundancy entities. Each entity specifies a kind and level of redundancy and a collection, or redundancy set, of other computer systems that provide the specified redundancy to this comput... |
| `Redundancy@odata.count` | count | No | see mockup |
| `SKU` | string | No | The manufacturer SKU for this system. |
| `SecureBoot` | SecureBoot | No | The link to the UEFI Secure Boot associated with this system. |
| `SerialConsole` | HostSerialConsole | No | The serial console services that this system provides. |
| `SerialNumber` | string | No | The serial number for this system. |
| `SimpleStorage` | SimpleStorageCollection | No | The link to the collection of storage devices associated with this system. |
| `Status` | Status | No | The status and health of the resource and its subordinate or dependent resources. |
| `Storage` | StorageCollection | No | The link to the collection of storage devices associated with this system. |
| `SubModel` | string | No | The sub-model for this system. |
| `SystemType` | SystemType | No | The type of computer system that this resource represents. |
| `TrustedModules` | array of TrustedModules | No | An array of trusted modules in the system. |
| `USBControllers` | USBControllerCollection | No | The link to a collection of USB controllers for this system. |
| `UUID` | UUID | No | The UUID for this system. |
| `VirtualMedia` | VirtualMediaCollection | No | The link to the virtual media services for this system. |
| `VirtualMediaConfig` | VirtualMediaConfig | No | The information about the virtual media service of this system. |
| `Virtualization` | Virtualization | No | The information about the virtualization abilities of this system. |

