# Thermal

Thermal telemetry and control for a Chassis: fans, temperatures, and thermal redundancy.

**Schema definition:** `Thermal`  

**Example source (DMTF mockup):** `Chassis/1U/Thermal/index.json`


## Example payload

```json
{
  "@odata.type": "#Thermal.v1_7_2.Thermal",
  "Id": "Thermal",
  "Name": "Thermal",
  "Temperatures": [
    {
      "@odata.id": "/redfish/v1/Chassis/1U/Thermal#/Temperatures/0",
      "MemberId": "0",
      "Name": "CPU1 Temp",
      "SensorNumber": 5,
      "Status": {
        "State": "Enabled",
        "Health": "OK"
      },
      "ReadingCelsius": 41,
      "UpperThresholdNonCritical": 42,
      "UpperThresholdCritical": 45,
      "UpperThresholdFatal": 48,
      "MinReadingRangeTemp": 0,
      "MaxReadingRangeTemp": 60,
      "PhysicalContext": "CPU",
      "RelatedItem": [
        {
          "@odata.id": "/redfish/v1/Systems/437XR1138R2/Processors/CPU1"
        }
      ]
    },
    {
      "@odata.id": "/redfish/v1/Chassis/1U/Thermal#/Temperatures/1",
      "MemberId": "1",
      "Name": "CPU2 Temp",
      "SensorNumber": 6,
      "Status": {
        "State": "Disabled"
      },
      "UpperThresholdNonCritical": 42,
      "UpperThresholdCritical": 45,
      "UpperThresholdFatal": 48,
      "MinReadingRangeTemp": 0,
      "MaxReadingRangeTemp": 60,
      "PhysicalContext": "CPU",
      "RelatedItem": [
        {
          "@odata.id": "/redfish/v1/Systems/437XR1138R2/Processors/CPU2"
        }
      ]
    }
  ],
  "Fans": [
    {
      "@odata.id": "/redfish/v1/Chassis/1U/Thermal#/Fans/0",
      "MemberId": "0",
      "Name": "BaseBoard System Fan",
      "PhysicalContext": "Backplane",
      "Status": {
        "State": "Enabled",
        "Health": "OK"
      },
      "Reading": 2100,
      "ReadingUnits": "RPM",
      "LowerThresholdFatal": 0,
      "MinReadingRange": 0,
      "MaxReadingRange": 5000,
      "Redundancy": [
        {
          "@odata.id": "/redfish/v1/Chassis/1U/Thermal#/Redundancy/0"
        }
      ],
      "RelatedItem": [
        {
          "@odata.id": "/redfish/v1/Systems/437XR1138R2"
        },
        {
          "@odata.id": "/redfish/v1/Chassis/1U"
        }
      ]
    },
    {
      "@odata.id": "/redfish/v1/Chassis/1U/Thermal#/Fans/1",
      "MemberId": "1",
      "Name": "BaseBoard System Fan Backup",
      "PhysicalContext": "Backplane",
      "Status": {
        "State": "Enabled",
        "Health": "OK"
      },
      "Reading": 2050,
      "ReadingUnits": "RPM",
      "LowerThresholdFatal": 0,
      "MinReadingRange": 0,
      "MaxReadingRange": 5000,
      "Redundancy": [
        {
          "@odata.id": "/redfish/v1/Chassis/1U/Thermal#/Redundancy/0"
        }
      ],
      "RelatedItem": [
        {
          "@odata.id": "/redfish/v1/Systems/437XR1138R2"
        },
        {
          "@odata.id": "/redfish/v1/Chassis/1U"
        }
      ]
    }
  ],
  "Redundancy": [
    {
      "@odata.id": "/redfish/v1/Chassis/1U/Thermal#/Redundancy/0",
      "MemberId": "0",
      "Name": "BaseBoard System Fans",
      "RedundancySet": [
        {
          "@odata.id": "/redfish/v1/Chassis/1U/Thermal#/Fans/0"
        },
        {
          "@odata.id": "/redfish/v1/Chassis/1U/Thermal#/Fans/1"
        }
      ],
      "Mode": "N+m",
      "Status": {
        "State": "Enabled",
        "Health": "OK"
      },
      "MinNumNeeded": 1,
      "MaxNumSupported": 2
    }
  ],
  "@odata.id": "/redfish/v1/Chassis/1U/Thermal",
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
| `Actions` | ThermalActions | No | The available actions for this resource. |
| `Description` | Description | No | see mockup |
| `Fans` | array of Fan | No | The set of fans for this chassis. |
| `Fans@odata.count` | count | No | see mockup |
| `Id` | Id | Yes | see mockup |
| `Name` | Name | Yes | see mockup |
| `Oem` | Oem | No | The OEM extension property. |
| `Redundancy` | array of Redundancy | No | The redundancy information for the set of fans in this chassis. |
| `Redundancy@odata.count` | count | No | see mockup |
| `Status` | Status | No | The status and health of the resource and its subordinate or dependent resources. |
| `Temperatures` | array of Temperature | No | The set of temperature sensors for this chassis. |
| `Temperatures@odata.count` | count | No | see mockup |

