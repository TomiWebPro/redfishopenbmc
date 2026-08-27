# SoftwareInventory

Describes one firmware/software inventory item (version, build, state, updatable). A member of the FirmwareInventory/SoftwareInventory collections.

**Schema definition:** `SoftwareInventory`  

**Example source (DMTF mockup):** `UpdateService/FirmwareInventory/BMC/index.json`


## Example payload

```json
{
  "@odata.type": "#SoftwareInventory.v1_10_1.SoftwareInventory",
  "Id": "BMC",
  "Name": "Contoso BMC Firmware",
  "Status": {
    "State": "Enabled",
    "Health": "OK"
  },
  "Updateable": true,
  "Manufacturer": "Contoso",
  "ReleaseDate": "2017-08-22T12:00:00Z",
  "Version": "1.45.455b66-rev4",
  "SoftwareId": "1624A9DF-5E13-47FC-874A-DF3AFF143089",
  "LowestSupportedVersion": "1.30.367a12-rev1",
  "UefiDevicePaths": [
    "BMC(0x1,0x0ABCDEF)"
  ],
  "AdditionalVersions": {
    "Bootloader": "v2022.01",
    "Kernel": "Linux 5.13.0-30-generic arm71",
    "Oem": {
      "Contoso": {
        "@odata.type": "#ContosoSoftwareInventory.v1_0_0.AdditionalVersions",
        "ManagementApp": "1.30"
      }
    }
  },
  "RelatedItem": [
    {
      "@odata.id": "/redfish/v1/Managers/BMC"
    }
  ],
  "@odata.id": "/redfish/v1/UpdateService/FirmwareInventory/BMC",
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
| `Active` | boolean | No | This image is active on one or more devices. |
| `AdditionalVersions` | AdditionalVersions | No | The additional versions of this software. |
| `AssociatedPhysicalContext` | PhysicalContext | No | The area or device to which the software applies. Used to distinguish when different parts of a device have different software components. |
| `Description` | Description | No | see mockup |
| `Id` | Id | Yes | see mockup |
| `ImageDataURI` | string | No | The URI at which to access the software inventory image. |
| `Links` | Links | No | The links to other resources that are related to this resource. |
| `LowestSupportedVersion` | string | No | The lowest supported version of this software. |
| `Manufacturer` | string | No | The manufacturer or producer of this software. |
| `Measurement` | MeasurementBlock | No | A DSP0274-defined measurement block. |
| `Name` | Name | Yes | see mockup |
| `Oem` | Oem | No | The OEM extension property. |
| `RelatedItem` | array of idRef | No | An array of links to resources or objects that represent devices to which this software inventory applies. |
| `RelatedItem@odata.count` | count | No | see mockup |
| `ReleaseDate` | string | No | The release date of this software. |
| `ReleaseType` | ReleaseType | No | The type of release. |
| `ResetRequiredOnUpdate` | boolean | No | An indication of whether a reset is required to apply an update to this software. |
| `SizeBytes` | integer | No | The size of the software image in bytes. |
| `SoftwareId` | string | No | The implementation-specific label that identifies this software. |
| `Staged` | boolean | No | This image is ready to be activated to one or more devices. |
| `Status` | Status | No | The status and health of the resource and its subordinate or dependent resources. |
| `UefiDevicePaths` | array of string | No | The list of UEFI device paths of the components associated with this software inventory item. |
| `Updateable` | boolean | No | An indication of whether the update service can update this software. |
| `Version` | string | No | The version of this software. |
| `VersionScheme` | VersionScheme | No | The format of the version. |
| `WriteProtected` | boolean | No | Indicates if the software is write-protected. |

