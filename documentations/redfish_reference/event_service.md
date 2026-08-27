# EventService

Manages event subscriptions (push telemetry/alerts to subscribers). Top resource under /redfish/v1/EventService.

**Schema definition:** `EventService`  

**Example source (DMTF mockup):** `EventService/index.json`


## Example payload

```json
{
  "@odata.type": "#EventService.v1_10_1.EventService",
  "Id": "EventService",
  "Name": "Event Service",
  "Status": {
    "State": "Enabled",
    "Health": "OK"
  },
  "ServiceEnabled": true,
  "DeliveryRetryAttempts": 3,
  "DeliveryRetryIntervalSeconds": 60,
  "EventTypesForSubscription": [
    "StatusChange",
    "ResourceUpdated"
  ],
  "Subscriptions": {
    "@odata.id": "/redfish/v1/EventService/Subscriptions"
  },
  "Actions": {
    "#EventService.SubmitTestEvent": {
      "target": "/redfish/v1/EventService/Actions/EventService.SubmitTestEvent",
      "@Redfish.ActionInfo": "/redfish/v1/EventService/SubmitTestEventActionInfo"
    }
  },
  "SMTP": {
    "ServiceEnabled": true,
    "Port": 25,
    "ServerAddress": "smtp.contoso.com",
    "FromAddress": "no_reply@contoso.com",
    "ConnectionProtocol": "AutoDetect",
    "Authentication": "AutoDetect",
    "Username": "employee123",
    "Password": null
  },
  "@odata.id": "/redfish/v1/EventService",
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
| `DeliveryRetryAttempts` | integer | No | The number of times that the `POST` of an event is retried before the subscription terminates or is suspended. This retry occurs at the service level, which means that the HTTP `POST` to the event destination fails wi... |
| `DeliveryRetryIntervalSeconds` | integer | No | The interval, in seconds, between retry attempts for sending any event. |
| `Description` | Description | No | see mockup |
| `EventFormatTypes` | array of EventFormatType | No | The content types of the message that this service can send to the event destination. |
| `EventTypesForSubscription` | array of EventType | No | The types of events to which a client can subscribe. |
| `ExcludeMessageId` | boolean | No | An indication of whether the service supports filtering by the `ExcludeMessageIds` property. |
| `ExcludeRegistryPrefix` | boolean | No | An indication of whether the service supports filtering by the `ExcludeRegistryPrefixes` property. |
| `Id` | Id | Yes | see mockup |
| `IncludeOriginOfConditionSupported` | boolean | No | An indication of whether the service supports including the resource payload of the origin of condition in the event payload. |
| `Name` | Name | Yes | see mockup |
| `Oem` | Oem | No | The OEM extension property. |
| `OriginResourcesSupported` | boolean | No | An indication of whether the service supports filtering by the `OriginResources` property. |
| `RegistryPrefixes` | array of string | No | The list of the prefixes of the message registries that can be used for the `RegistryPrefixes` or `ExcludeRegistryPrefixes` properties on a subscription. If this property is absent or contains an empty array, the serv... |
| `ResourceTypes` | array of string | No | The list of `@odata.type` values, or schema names, that can be specified in the `ResourceTypes` array in a subscription. If this property is absent or contains an empty array, the service does not support resource typ... |
| `SMTP` | SMTP | No | Settings for SMTP event delivery. |
| `SSEFilterPropertiesSupported` | SSEFilterPropertiesSupported | No | The set of properties that are supported in the `$filter` query parameter for the `ServerSentEventUri`. |
| `SSEIncludeOriginOfConditionSupported` | boolean | No | An indication of whether the service supports the `includeoriginofcondition` query parameter for the `ServerSentEventUri`. |
| `ServerSentEventUri` | string | No | The link to a URI for receiving Server-Sent Event representations for the events that this service generates. |
| `ServiceEnabled` | boolean | No | An indication of whether this service is enabled. If `false`, events are no longer published, new SSE connections cannot be established, and existing SSE connections are terminated. |
| `Severities` | array of Health | No | The list of severities that can be specified in the `Severities` array in a subscription. |
| `Status` | Status | No | The status and health of the resource and its subordinate or dependent resources. |
| `SubordinateResourcesSupported` | boolean | No | An indication of whether the service supports the `SubordinateResources` property on both event subscriptions and generated events. |
| `Subscriptions` | EventDestinationCollection | No | The link to a collection of event destinations. |

