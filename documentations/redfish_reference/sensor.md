# Sensor

A single sensor reading (temperature, fan, voltage, power, current, energy, etc.). Collected under Chassis/{id}/Sensors.

**Schema definition:** `Sensor`  

**Example source (DMTF mockup):** `Chassis/1U/Sensors/FanBay2/index.json`


## Example payload

```json
{
  "@odata.type": "#Sensor.v1_8_1.Sensor",
  "Id": "FanBay2",
  "Name": "Chassis Fan #2",
  "PhysicalContext": "Chassis",
  "Reading": 45,
  "ReadingRangeMax": 100,
  "ReadingRangeMin": 0,
  "ReadingType": "Percent",
  "ReadingUnits": "%",
  "Status": {
    "Health": "OK",
    "State": "Enabled"
  },
  "Thresholds": {
    "LowerCaution": {
      "Reading": 5
    },
    "LowerCritical": {
      "Reading": 0
    }
  },
  "@odata.id": "/redfish/v1/Chassis/1U/Sensors/FanBay2",
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
| `Accuracy` | number | No | The estimated percent error of measured versus actual values. |
| `Actions` | Actions | No | The available actions for this resource. |
| `AdjustedMaxAllowableOperatingValue` | number | No | The adjusted maximum allowable operating value for this equipment based on the environmental conditions. |
| `AdjustedMinAllowableOperatingValue` | number | No | The adjusted minimum allowable operating value for this equipment based on the environmental conditions. |
| `ApparentVA` | number | No | The product of voltage and current for an AC circuit, in volt-ampere units. |
| `ApparentkVAh` | number | No | Apparent energy (kVAh). |
| `AverageReading` | number | No | The average sensor value. |
| `AveragingInterval` | string | No | The interval over which the average sensor value is calculated. |
| `AveragingIntervalAchieved` | boolean | No | Indicates that enough readings were collected to calculate the average sensor reading over the averaging interval time. |
| `Calibration` | number | No | The calibration offset applied to the Reading. |
| `CalibrationTime` | string | No | The date and time that the sensor was last calibrated. |
| `CrestFactor` | number | No | The crest factor for this sensor. |
| `Description` | Description | No | see mockup |
| `ElectricalContext` | ElectricalContext | No | The combination of current-carrying conductors. |
| `Enabled` | boolean | No | Indicates whether the sensor is enabled and provides a reading. |
| `Id` | Id | Yes | see mockup |
| `Implementation` | ImplementationType | No | The implementation of the sensor. |
| `LifetimeReading` | number | No | The total accumulation value for this sensor. |
| `LifetimeStartDateTime` | string | No | The date and time when the sensor started accumulating readings for the `LifetimeReading` property. |
| `Links` | Links | No | The links to other resources that are related to this resource. |
| `LoadPercent` | number | No | The power load utilization for this sensor. |
| `Location` | Location | No | The location information for this sensor. |
| `LowestIntervalReading` | number | No | The lowest sensor value over a time interval. |
| `LowestReading` | number | No | The lowest sensor value. |
| `LowestReadingTime` | string | No | The time when the lowest sensor value occurred. |
| `Manufacturer` | string | No | The manufacturer of this sensor. |
| `MaxAllowableOperatingValue` | number | No | The maximum allowable operating value for this equipment. |
| `MinAllowableOperatingValue` | number | No | The minimum allowable operating value for this equipment. |
| `Model` | string | No | The model number of the sensor. |
| `Name` | Name | Yes | see mockup |
| `Oem` | Oem | No | The OEM extension property. |
| `PartNumber` | string | No | The part number of the sensor. |
| `PeakIntervalReading` | number | No | The peak sensor value over a time interval. |
| `PeakReading` | number | No | The peak sensor value. |
| `PeakReadingTime` | string | No | The time when the peak sensor value occurred. |
| `PhaseAngleDegrees` | number | No | The phase angle (degrees) between the current and voltage waveforms. |
| `PhysicalContext` | PhysicalContext | No | The area or device to which this sensor measurement applies. |
| `PhysicalSubContext` | PhysicalSubContext | No | The usage or location within a device to which this sensor measurement applies. |
| `PowerFactor` | number | No | The power factor for this sensor. |
| `Precision` | number | No | The number of significant digits in the reading. |
| `ReactiveVAR` | number | No | The square root of the difference term of squared apparent VA and squared power (Reading) for a circuit, in VAR units. |
| `ReactivekVARh` | number | No | Reactive energy (kVARh). |
| `Reading` | number | No | The sensor value. |
| `ReadingAccuracy` | number | No | Accuracy (+/-) of the reading. |
| `ReadingBasis` | ReadingBasisType | No | The basis for the reading of this sensor. |
| `ReadingRangeMax` | number | No | The maximum possible value for this sensor. |
| `ReadingRangeMin` | number | No | The minimum possible value for this sensor. |
| `ReadingTime` | string | No | The date and time that the reading was acquired from the sensor. |
| `ReadingType` | ReadingType | No | The type of sensor. |
| `ReadingUnits` | string | No | The units of the reading, thresholds, and other reading-related properties in UCUM c/s format. |
| `RelatedItem` | array of idRef | No | An array of links to resources or objects that this sensor services. |
| `RelatedItem@odata.count` | count | No | see mockup |
| `SKU` | string | No | The SKU of the sensor. |
| `SensingFrequency` | number | No | The time interval between readings of the physical sensor. |
| `SensingInterval` | string | No | The time interval between readings of the sensor. |
| `SensorGroup` | RedundantGroup | No | The group of sensors that provide readings for this sensor. |
| `SensorResetTime` | string | No | The date and time when the time-based properties were last reset. |
| `SerialNumber` | string | No | The serial number of the sensor. |
| `SparePartNumber` | string | No | The spare part number of the sensor. |
| `SpeedRPM` | number | No | The rotational speed. |
| `Status` | Status | No | The status and health of the resource and its subordinate or dependent resources. |
| `THDPercent` | number | No | The total harmonic distortion percent (% THD). |
| `Thresholds` | Thresholds | No | The set of thresholds defined for this sensor. |
| `UserLabel` | string | No | A user-assigned label. |
| `VoltageType` | VoltageType | No | The voltage type for this sensor. |

