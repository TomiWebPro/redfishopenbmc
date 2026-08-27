# SessionService

Manages login sessions. Top resource under /redfish/v1/SessionService; POST here to authenticate.

**Schema definition:** `SessionService`  

**Example source (DMTF mockup):** `SessionService/index.json`


## Example payload

```json
{
  "@odata.type": "#SessionService.v1_1_8.SessionService",
  "Id": "SessionService",
  "Name": "Session Service",
  "Description": "Session Service",
  "Status": {
    "State": "Enabled",
    "Health": "OK"
  },
  "ServiceEnabled": true,
  "SessionTimeout": 30,
  "Sessions": {
    "@odata.id": "/redfish/v1/SessionService/Sessions"
  },
  "@odata.id": "/redfish/v1/SessionService",
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
| `AbsoluteSessionTimeout` | integer | No | The maximum number of seconds that a session is open before the service closes the session regardless of activity. |
| `AbsoluteSessionTimeoutEnabled` | boolean | No | An indication of whether an absolute session timeout is applied to sessions. |
| `Actions` | Actions | No | The available actions for this resource. |
| `Description` | Description | No | see mockup |
| `Id` | Id | Yes | see mockup |
| `Name` | Name | Yes | see mockup |
| `Oem` | Oem | No | The OEM extension property. |
| `ServiceEnabled` | boolean | No | An indication of whether this service is enabled. If `true`, this service is enabled. If `false`, it is disabled, and new sessions cannot be created, old sessions cannot be deleted, and established sessions can contin... |
| `SessionTimeout` | integer | No | The number of seconds of inactivity that a session can have before the session service closes the session due to inactivity. |
| `Sessions` | SessionCollection | No | The link to a collection of sessions. |
| `Status` | Status | No | The status and health of the resource and its subordinate or dependent resources. |

