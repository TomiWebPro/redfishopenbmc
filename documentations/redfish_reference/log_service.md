# LogService

A log (system log, event log, SEL). Contains Entries collection. Found under Managers/*/LogServices and Systems/*/LogServices.

**Schema definition:** `LogService`  

**Example source (DMTF mockup):** `Managers/BMC/LogServices/Log/index.json`


## Example payload

```json
{
  "@odata.type": "#LogService.v1_6_0.LogService",
  "Id": "Log",
  "Name": "System Log Service",
  "MaxNumberOfRecords": 1000,
  "OverWritePolicy": "WrapsWhenFull",
  "DateTime": "2015-03-13T04:14:33+06:00",
  "DateTimeLocalOffset": "+06:00",
  "ServiceEnabled": true,
  "Status": {
    "State": "Enabled",
    "Health": "OK"
  },
  "Actions": {
    "#LogService.ClearLog": {
      "target": "/redfish/v1/Managers/BMC/LogServices/Log/Actions/LogService.ClearLog"
    }
  },
  "Entries": {
    "@odata.id": "/redfish/v1/Managers/BMC/LogServices/Log/Entries"
  },
  "@odata.id": "/redfish/v1/Managers/BMC/LogServices/Log",
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
| `AutoClearResolvedEntries` | AutoClearResolvedEntries | No | Indicates if this log service automatically clears the resolved log entries. |
| `AutoDSTEnabled` | boolean | No | An indication of whether the log service is configured for automatic Daylight Saving Time (DST) adjustment. |
| `DateTime` | string | No | The current date and time with UTC offset of the log service. |
| `DateTimeLocalOffset` | string | No | The time offset from UTC that the `DateTime` property is in `+HH:MM` format. |
| `Description` | Description | No | see mockup |
| `DiagnosticDataDetails` | array of DiagnosticDataDetails | No | The detailed information for the data collected with the `CollectDiagnosticData` action. |
| `Entries` | LogEntryCollection | No | The link to the log entry collection. |
| `Id` | Id | Yes | see mockup |
| `LogEntryType` | LogEntryTypes | No | The format of the log entries. |
| `LogPurposes` | array of LogPurpose | No | The purposes of the log. |
| `MaxNumberOfRecords` | integer | No | The maximum number of log entries that this service can have. |
| `Name` | Name | Yes | see mockup |
| `OEMLogPurpose` | string | No | The OEM-specified purpose of the log if `LogPurposes` contains `OEM`. |
| `Oem` | Oem | No | The OEM extension property. |
| `OverWritePolicy` | OverWritePolicy | No | The overwrite policy for this service that takes place when the log is full. |
| `Overflow` | boolean | No | Indicates whether the log service has overflowed. |
| `Persistency` | boolean | No | Indicates whether the log service is persistent across a cold reset. |
| `ServiceEnabled` | boolean | No | An indication of whether this service is enabled. |
| `Status` | Status | No | The status and health of the resource and its subordinate or dependent resources. |
| `SyslogFilters` | array of SyslogFilter | No | A list of syslog message filters to be logged locally. |

