/// Per-tile rebuild fingerprints for the sensor telemetry list (issue #007).
///
/// These pure-Dart helpers encode exactly the fields a single tile renders —
/// identity, current reading, health/state, physical context, reading type and
/// units, and thresholds. A polling parent can compare a tile's fingerprint
/// between ticks and keep the identical widget instance when nothing the tile
/// shows has changed, so unchanged tiles neither rebuild nor repaint
/// (`SensorDeltaTile`). Transient fields such as `sourceUri` and the sparkline
/// history are deliberately excluded: history advances every poll even for a
/// flat sensor, and adding one identical sample does not change what the tile
/// communicates (a flat trend stays flat).
library;

import 'sensor_models.dart';

/// Fingerprint of everything a temperature tile renders.
String temperatureTileFingerprint(ThermalReading r) {
  final StringBuffer out = StringBuffer()
    ..write('t|')
    ..write(r.name)
    ..write('|')
    ..write(r.readingCelsius)
    ..write('|')
    ..write(r.status.health)
    ..write('|')
    ..write(r.status.state)
    ..write('|')
    ..write(r.physicalContext)
    ..write('|')
    ..write(r.lowerCritical)
    ..write('|')
    ..write(r.lowerCaution)
    ..write('|')
    ..write(r.upperCaution)
    ..write('|')
    ..write(r.upperCritical);
  return out.toString();
}

/// Fingerprint of everything a fan tile renders.
String fanTileFingerprint(FanReading r) {
  final StringBuffer out = StringBuffer()
    ..write('f|')
    ..write(r.name)
    ..write('|')
    ..write(r.reading)
    ..write('|')
    ..write(r.status.health)
    ..write('|')
    ..write(r.status.state)
    ..write('|')
    ..write(r.physicalContext)
    ..write('|')
    ..write(r.upperCritical);
  return out.toString();
}

/// Fingerprint of everything a generic sensor tile renders.
///
/// Threshold entries are appended in map iteration order to match the order
/// the tile displays them; the service builds the map deterministically from
/// the Redfish payload so that order is stable between polls.
String sensorTileFingerprint(SensorReading r) {
  final StringBuffer out = StringBuffer()
    ..write('s|')
    ..write(r.name)
    ..write('|')
    ..write(r.reading)
    ..write('|')
    ..write(r.status.health)
    ..write('|')
    ..write(r.status.state)
    ..write('|')
    ..write(r.readingType)
    ..write('|')
    ..write(r.readingUnits)
    ..write('|');
  for (final MapEntry<String, double> e in r.thresholds.entries) {
    out
      ..write(e.key)
      ..write('=')
      ..write(e.value)
      ..write(',');
  }
  return out.toString();
}
