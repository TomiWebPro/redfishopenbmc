# UpdateService

Firmware/software update control: SimpleUpdate action, FirmwareInventory and SoftwareInventory collections.

**Schema definition:** `UpdateService`  

**Example source (DMTF mockup):** `UpdateService/index.json`


## Example payload

```json
{
  "@odata.type": "#UpdateService.v1_13_0.UpdateService",
  "Id": "UpdateService",
  "Name": "Update service",
  "Status": {
    "State": "Enabled",
    "Health": "OK",
    "HealthRollup": "OK"
  },
  "ServiceEnabled": true,
  "HttpPushUri": "/FWUpdate",
  "HttpPushUriOptions": {
    "HttpPushUriApplyTime": {
      "ApplyTime": "Immediate",
      "ApplyTime@Redfish.AllowableValues": [
        "Immediate",
        "OnReset"
      ],
      "MaintenanceWindowStartTime": "2018-12-01T03:00:00+06:00",
      "MaintenanceWindowDurationInSeconds": 600
    }
  },
  "HttpPushUriOptionsBusy": false,
  "FirmwareInventory": {
    "@odata.id": "/redfish/v1/UpdateService/FirmwareInventory"
  },
  "ClientCertificates": {
    "@odata.id": "/redfish/v1/UpdateService/ClientCertificates"
  },
  "Actions": {
    "#UpdateService.SimpleUpdate": {
      "target": "/redfish/v1/UpdateService/Actions/SimpleUpdate",
      "@Redfish.ActionInfo": "/redfish/v1/UpdateService/SimpleUpdateActionInfo"
    }
  },
  "@odata.id": "/redfish/v1/UpdateService",
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
| `ClientCertificates` | CertificateCollection | No | The link to a collection of client identity certificates provided to the server referenced by the `ImageURI` parameter in `SimpleUpdate`. |
| `Description` | Description | No | see mockup |
| `FirmwareInventory` | SoftwareInventoryCollection | No | An inventory of firmware. |
| `HttpPushUri` | string | No | The URI used to perform an HTTP or HTTPS push update to the update service. The format of the message is vendor-specific. |
| `HttpPushUriOptions` | HttpPushUriOptions | No | The options for `HttpPushUri`-provided software updates. |
| `HttpPushUriOptionsBusy` | boolean | No | An indication of whether a client has reserved the `HttpPushUriOptions` properties for software updates. |
| `HttpPushUriTargets` | array of string | No | An array of URIs that indicate where to apply the update image. |
| `HttpPushUriTargetsBusy` | boolean | No | An indication of whether any client has reserved the `HttpPushUriTargets` property. |
| `Id` | Id | Yes | see mockup |
| `LocalImageStore` | SoftwareInventoryCollection | No | An inventory of locally stored images. |
| `LocalImageStoreAvailableCapacityBytes` | integer | No | The number of bytes currently available in the local image store. |
| `LocalImageStoreTotalCapacityBytes` | integer | No | The total number of bytes available to the local image store. |
| `MaxImageSizeBytes` | integer | No | The maximum size in bytes of the software update image that this service supports. |
| `MultipartHttpPushUri` | string | No | The URI used to perform a Redfish Specification-defined multipart HTTP or HTTPS push update to the update service. |
| `Name` | Name | Yes | see mockup |
| `Oem` | Oem | No | The OEM extension property. |
| `PublicIdentitySSHKey` | Key | No | A link to the public key that is used with the `SimpleUpdate` action for the key-based authentication. The GenerateSSHIdentityKeyPair and RemoveSSHIdentityKeyPair are used to update the key for the `SimpleUpdate` action. |
| `RemoteServerCertificates` | CertificateCollection | No | The link to a collection of server certificates for the server referenced by the `ImageURI` parameter in SimpleUpdate. |
| `RemoteServerSSHKeys` | KeyCollection | No | The link to a collection of keys that can be used to authenticate the server referenced by the `ImageURI` parameter in `SimpleUpdate`. |
| `ServiceEnabled` | boolean | No | An indication of whether this service is enabled. |
| `SoftwareInventory` | SoftwareInventoryCollection | No | An inventory of software. |
| `Status` | Status | No | The status and health of the resource and its subordinate or dependent resources. |
| `SupportedUpdateImageFormats` | array of SupportedUpdateImageFormatType | No | The image format types supported by the service. |
| `UpdateServiceCapabilities` | UpdateServiceCapabilities | No | A link to the capabilities of the update service. |
| `VerifyRemoteServerCertificate` | boolean | No | An indication of whether the service will verify the certificate of the server referenced by the `ImageURI` parameter in `SimpleUpdate` prior to sending the transfer request. |
| `VerifyRemoteServerSSHKey` | boolean | No | An indication of whether the service will verify the SSH key of the server referenced by the `ImageURI` parameter in `SimpleUpdate` prior to sending the transfer request. |

