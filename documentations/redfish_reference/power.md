# Power

Power telemetry and control for a Chassis: power supplies, power/energy consumption, voltage and redundancy.

**Schema definition:** `Power`  

**Example source (DMTF mockup):** `Chassis/1U/Power/index.json`


## Example payload

```json
{
  "@odata.type": "#Power.v1_7_2.Power",
  "Id": "Power",
  "Name": "Power",
  "PowerControl": [
    {
      "@odata.id": "/redfish/v1/Chassis/1U/Power#/PowerControl/0",
      "MemberId": "0",
      "Name": "System Input Power",
      "PowerConsumedWatts": 344,
      "PowerRequestedWatts": 800,
      "PowerAvailableWatts": 0,
      "PowerCapacityWatts": 800,
      "PowerAllocatedWatts": 800,
      "PowerMetrics": {
        "IntervalInMin": 30,
        "MinConsumedWatts": 271,
        "MaxConsumedWatts": 489,
        "AverageConsumedWatts": 319
      },
      "PowerLimit": {
        "LimitInWatts": 500,
        "LimitException": "LogEventOnly",
        "CorrectionInMs": 50
      },
      "RelatedItem": [
        {
          "@odata.id": "/redfish/v1/Systems/437XR1138R2"
        },
        {
          "@odata.id": "/redfish/v1/Chassis/1U"
        }
      ],
      "Status": {
        "State": "Enabled",
        "Health": "OK"
      }
    }
  ],
  "Voltages": [
    {
      "@odata.id": "/redfish/v1/Chassis/1U/Power#/Voltages/0",
      "MemberId": "0",
      "Name": "VRM1 Voltage",
      "SensorNumber": 11,
      "Status": {
        "State": "Enabled",
        "Health": "OK"
      },
      "ReadingVolts": 12,
      "UpperThresholdNonCritical": 12.5,
      "UpperThresholdCritical": 13,
      "UpperThresholdFatal": 15,
      "LowerThresholdNonCritical": 11.5,
      "LowerThresholdCritical": 11,
      "LowerThresholdFatal": 10,
      "MinReadingRange": 0,
      "MaxReadingRange": 20,
      "PhysicalContext": "VoltageRegulator",
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
      "@odata.id": "/redfish/v1/Chassis/1U/Power#/Voltages/1",
      "MemberId": "1",
      "Name": "VRM2 Voltage",
      "SensorNumber": 12,
      "Status": {
        "State": "Enabled",
        "Health": "OK"
      },
      "ReadingVolts": 5,
      "UpperThresholdNonCritical": 5.5,
      "UpperThresholdCritical": 7,
      "LowerThresholdNonCritical": 4.75,
      "LowerThresholdCritical": 4.5,
      "MinReadingRange": 0,
      "MaxReadingRange": 20,
      "PhysicalContext": "VoltageRegulator",
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
  "PowerSupplies": [
    {
      "@odata.id": "/redfish/v1/Chassis/1U/Power#/PowerSupplies/0",
      "MemberId": "0",
      "Name": "Power Supply Bay",
      "Status": {
        "State": "Enabled",
        "Health": "Warning"
      },
      "PowerSupplyType": "AC",
      "LineInputVoltageType": "ACWideRange",
      "LineInputVoltage": 120,
      "PowerCapacityWatts": 800,
      "LastPowerOutputWatts": 325,
      "Model": "499253-B21",
      "Manufacturer": "ManufacturerName",
      "FirmwareVersion": "1.00",
      "SerialNumber": "1Z0000001",
      "PartNumber": "0000001A3A",
      "SparePartNumber": "0000001A3A",
      "InputRanges": [
        {
          "InputType": "AC",
          "MinimumVoltage": 100,
          "MaximumVoltage": 120,
          "OutputWattage": 800
        },
        {
          "InputType": "AC",
          "MinimumVoltage": 200,
          "MaximumVoltage": 240,
          "OutputWattage": 1300
        }
      ],
      "RelatedItem": [
        {
          "@odata.id": "/redfish/v1/Chassis/1U"
        }
      ]
    }
  ],
  "@odata.id": "/redfish/v1/Chassis/1U/Power",
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
| `Description` | Description | No | see mockup |
| `Id` | Id | Yes | see mockup |
| `Name` | Name | Yes | see mockup |
| `Oem` | Oem | No | The OEM extension property. |
| `PowerControl` | array of PowerControl | No | The set of power control functions, including power reading and limiting. |
| `PowerControl@odata.count` | count | No | see mockup |
| `PowerSupplies` | array of PowerSupply | No | The set of power supplies associated with this system or device. |
| `PowerSupplies@odata.count` | count | No | see mockup |
| `Redundancy` | array of Redundancy | No | The redundancy information for the set of power supplies in this chassis. |
| `Redundancy@odata.count` | count | No | see mockup |
| `Voltages` | array of Voltage | No | The set of voltage sensors for this chassis. |
| `Voltages@odata.count` | count | No | see mockup |

