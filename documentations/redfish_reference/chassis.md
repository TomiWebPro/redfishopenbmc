# Chassis

Represents a physical container or enclosure (rack, blade, board). Contains Power, Thermal, and Sensors sub-resources. Top resource under /redfish/v1/Chassis.

**Schema definition:** `Chassis`  

**Example source (DMTF mockup):** `Chassis/1U/index.json`


## Example payload

```json
{
  "@odata.type": "#Chassis.v1_25_0.Chassis",
  "Id": "1U",
  "Name": "Computer System Chassis",
  "ChassisType": "RackMount",
  "AssetTag": "Chicago-45Z-2381",
  "Manufacturer": "Contoso",
  "Model": "3500RX",
  "SKU": "8675309",
  "SerialNumber": "437XR1138R2",
  "PartNumber": "224071-J23",
  "PowerState": "On",
  "IndicatorLED": "Lit",
  "HeightMm": 44.45,
  "WidthMm": 431.8,
  "DepthMm": 711,
  "WeightKg": 15.31,
  "Location": {
    "PostalAddress": {
      "Country": "US",
      "Territory": "OR",
      "City": "Portland",
      "Street": "1001 SW 5th Avenue",
      "HouseNumber": 1100,
      "Name": "DMTF",
      "PostalCode": "97204"
    },
    "Placement": {
      "Row": "North",
      "Rack": "WEB43",
      "RackOffsetUnits": "EIA_310",
      "RackOffset": 12
    }
  },
  "Status": {
    "State": "Enabled",
    "Health": "OK"
  },
  "ThermalSubsystem": {
    "@odata.id": "/redfish/v1/Chassis/1U/ThermalSubsystem"
  },
  "PowerSubsystem": {
    "@odata.id": "/redfish/v1/Chassis/1U/PowerSubsystem"
  },
  "EnvironmentMetrics": {
    "@odata.id": "/redfish/v1/Chassis/1U/EnvironmentMetrics"
  },
  "Sensors": {
    "@odata.id": "/redfish/v1/Chassis/1U/Sensors"
  },
  "Controls": {
    "@odata.id": "/redfish/v1/Chassis/1U/Controls"
  },
  "TrustedComponents": {
    "@odata.id": "/redfish/v1/Chassis/1U/TrustedComponents"
  },
  "Thermal@Redfish.Deprecated": "Please migrate to use /redfish/v1/Chassis/1U/ThermalSubsystem",
  "Thermal": {
    "@odata.id": "/redfish/v1/Chassis/1U/Thermal"
  },
  "Power@Redfish.Deprecated": "Please migrate to use /redfish/v1/Chassis/1U/PowerSubsystem",
  "Power": {
    "@odata.id": "/redfish/v1/Chassis/1U/Power"
  },
  "Links": {
    "ComputerSystems": [
      {
        "@odata.id": "/redfish/v1/Systems/437XR1138R2"
      }
    ],
    "ManagedBy": [
      {
        "@odata.id": "/redfish/v1/Managers/BMC"
      }
    ],
    "ManagersInChassis": [
      {
        "@odata.id": "/redfish/v1/Managers/BMC"
      }
    ]
  },
  "@odata.id": "/redfish/v1/Chassis/1U",
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
| `Assembly` | Assembly | No | The link to the assembly associated with this chassis. |
| `AssetTag` | string | No | The user-assigned asset tag of this chassis. |
| `Certificates` | CertificateCollection | No | The link to a collection of certificates for device identity and attestation. |
| `ChassisType` | ChassisType | Yes | The type of physical form factor of the chassis. |
| `Controls` | ControlCollection | No | The link to the collection of controls located in this chassis. |
| `DepthMm` | number | No | The depth of the chassis. |
| `Description` | Description | No | see mockup |
| `Doors` | Doors | No | The doors or access panels of the chassis. |
| `Drives` | DriveCollection | No | The link to the collection of drives within this chassis. |
| `ElectricalSourceManagerURIs` | array of string | No | The URIs of the management interfaces for the external electrical source connections for this chassis. |
| `ElectricalSourceNames` | array of string | No | The names of the external electrical sources, such as circuits or outlets, connected to this chassis. |
| `EnvironmentMetrics` | EnvironmentMetrics | No | The link to the environment metrics for this chassis. |
| `EnvironmentalClass` | EnvironmentalClass | No | The ASHRAE Environmental Class for this chassis. |
| `FabricAdapters` | FabricAdapterCollection | No | The link to the collection of fabric adapters located in this chassis that provide access to fabric-related resource pools. |
| `HeatingCoolingEquipmentNames` | array of string | No | The names of the external heating or cooling equipment, such as coolant distribution units, connected to this chassis. |
| `HeatingCoolingManagerURIs` | array of string | No | The URIs of the management interfaces for the external heating or cooling equipment for this chassis. |
| `HeightMm` | number | No | The height of the chassis. |
| `HeightRackUnits` | number | No | The height of the rack-mountable chassis in rack units. |
| `HotPluggable` | boolean | No | An indication of whether this component can be inserted or removed while the equipment is in operation. |
| `Id` | Id | Yes | see mockup |
| `IndicatorLED` | IndicatorLED | No | The state of the indicator LED, which identifies the chassis. |
| `LeakDetectors` | LeakDetectorCollection | No | The link to the collection of leak detectors located in this chassis. |
| `Links` | Links | No | The links to other resources that are related to this resource. |
| `Location` | Location | No | The location of the chassis. |
| `LocationIndicatorActive` | boolean | No | An indicator allowing an operator to physically locate this resource. |
| `LogServices` | LogServiceCollection | No | The link to the logs for this chassis. |
| `Manufacturer` | string | No | The manufacturer of this chassis. |
| `MaxPowerWatts` | number | No | The upper bound of the total power consumed by the chassis. |
| `Measurements` | array of MeasurementBlock | No | An array of DSP0274-defined measurement blocks. |
| `MediaControllers` | MediaControllerCollection | No | The link to the collection of media controllers located in this chassis. |
| `Memory` | MemoryCollection | No | The link to the collection of memory located in this chassis that belong to fabric-related resource pools. |
| `MemoryDomains` | MemoryDomainCollection | No | The link to the collection of memory domains located in this chassis that belong to fabric-related resource pools. |
| `MinPowerWatts` | number | No | The lower bound of the total power consumed by the chassis. |
| `Model` | string | No | The model number of the chassis. |
| `Name` | Name | Yes | see mockup |
| `NetworkAdapters` | NetworkAdapterCollection | No | The link to the collection of network adapters associated with this chassis. |
| `Oem` | Oem | No | The OEM extension property. |
| `PCIeDevices` | PCIeDeviceCollection | No | The link to the collection of PCIe devices located in this chassis. |
| `PCIeSlots` | PCIeSlots | No | The link to the PCIe slot properties for this chassis. |
| `PartNumber` | string | No | The part number of the chassis. |
| `PhysicalSecurity` | PhysicalSecurity | No | The physical security state of the chassis. |
| `Power` | Power | No | The link to the power properties, or power supplies, power policies, and sensors, for this chassis. |
| `PowerState` | PowerState | No | The current power state of the chassis. |
| `PowerSubsystem` | PowerSubsystem | No | The link to the power subsystem properties for this chassis. |
| `PoweredByParent` | boolean | No | Indicates that the chassis receives power from the containing chassis. |
| `Processors` | ProcessorCollection | No | The link to the collection of processors located in this chassis that belong to fabric-related resource pools. |
| `RackMountCapacityUnits` | number | No | The usable capacity of rack units provided by this chassis. |
| `RackMountDepthMm` | number | No | The usable depth of the rack-mountable area of the chassis. |
| `RackMountWidth` | RackMountWidth | No | The width of the rack-mountable chassis or rack-mounting space. |
| `RackUnits` | RackUnits | No | The type of rack-mount units. |
| `ReadyToRemove` | boolean | No | An indication of whether the chassis is prepared by the system for removal. |
| `Replaceable` | boolean | No | An indication of whether this component can be independently replaced as allowed by the vendor's replacement policy. |
| `SKU` | string | No | The SKU of the chassis. |
| `Sensors` | SensorCollection | No | The link to the collection of sensors located in the equipment and sub-components. |
| `SerialNumber` | string | No | The serial number of the chassis. |
| `SparePartNumber` | string | No | The spare part number of the chassis. |
| `Status` | Status | No | The status and health of the resource and its subordinate or dependent resources. |
| `Thermal` | Thermal | No | The link to the thermal properties, such as fans, cooling, and sensors, for this chassis. |
| `ThermalDirection` | ThermalDirection | No | Indicates the thermal management path through the chassis. |
| `ThermalManagedByParent` | boolean | No | Indicates that the chassis is thermally managed by the parent chassis. |
| `ThermalSubsystem` | ThermalSubsystem | No | The link to the thermal subsystem properties for this chassis. |
| `TrustedComponents` | TrustedComponentCollection | No | The link to the trusted components in this chassis. |
| `UUID` | UUID | No | The UUID for this chassis. |
| `Version` | string | No | The hardware version of this chassis. |
| `WeightKg` | number | No | The weight of the chassis. |
| `WidthMm` | number | No | The width of the chassis. |

