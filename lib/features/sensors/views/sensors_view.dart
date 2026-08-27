import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redfishopenbmc/features/sensors/models/sensor_models.dart';
import 'package:redfishopenbmc/features/sensors/sensors_controller.dart';
import 'package:redfishopenbmc/features/sensors/sensors_providers.dart';
import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Sensor monitoring screen for a single system (issue #007).
///
/// Rendered only when the system advertises sensor monitoring
/// ([SystemFeatures.sensorMonitoring] is `true`); the [SystemShell] already
/// hides the tab otherwise, and this view additionally renders nothing when the
/// capability is absent so there is never a placeholder. Surfaces per-chassis
/// temperature, fan, and generic sensor readings pulled by [SensorsController].
class SensorsView extends ConsumerStatefulWidget {
  /// Creates a [SensorsView] for [systemId].
  const SensorsView({required this.systemId, super.key});

  /// Logical id of the system this view is scoped to.
  final String systemId;

  @override
  ConsumerState<SensorsView> createState() => _SensorsViewState();
}

class _SensorsViewState extends ConsumerState<SensorsView> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SensorsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.systemId != widget.systemId) _load();
  }

  void _load() {
    Future<void>.microtask(
      () => ref.read(sensorsControllerProvider(widget.systemId).notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SystemHandle? handle = ref.watch(systemHandleProvider(widget.systemId));
    final SystemFeatures? features = handle?.features;

    // Discovery not complete yet (or tab shown before capability gate).
    if (handle == null) {
      return const Center(child: Text('System not found'));
    }
    if (features == null) {
      return const Center(child: CircularProgressIndicator());
    }
    // Hard gate: no sensor monitoring → render nothing (no placeholder).
    if (!features.sensorMonitoring) {
      return const SizedBox.shrink();
    }

    final SensorsUiState ui = ref.watch(sensorsControllerProvider(widget.systemId));

    if (ui.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (ui.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            ui.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }
    if (ui.chassis.isEmpty) {
      return const Center(child: Text('No sensor data available'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        for (final ChassisSensors chassis in ui.chassis)
          _ChassisCard(chassis: chassis),
      ],
    );
  }
}

/// A single chassis card grouping its temperatures, fans, and sensors.
class _ChassisCard extends StatelessWidget {
  /// Creates a [_ChassisCard].
  const _ChassisCard({required this.chassis});

  /// The telemetry for one chassis.
  final ChassisSensors chassis;

  @override
  Widget build(BuildContext context) {
    final String title = chassis.chassisName ?? chassis.chassisId;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (chassis.thermal.isNotEmpty) ...<Widget>[
              Text('Temperatures', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              for (final ThermalReading t in chassis.thermal) _TemperatureTile(t),
              const SizedBox(height: 12),
            ],
            if (chassis.fans.isNotEmpty) ...<Widget>[
              Text('Fans', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              for (final FanReading f in chassis.fans) _FanTile(f),
              const SizedBox(height: 12),
            ],
            if (chassis.sensors.isNotEmpty) ...<Widget>[
              Text('Sensors', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              for (final SensorReading s in chassis.sensors) _SensorTile(s),
            ],
          ],
        ),
      ),
    );
  }
}

/// A temperature reading row with health tint and threshold hint.
class _TemperatureTile extends StatelessWidget {
  /// Creates a [_TemperatureTile].
  const _TemperatureTile(this.reading);

  /// The temperature reading to render.
  final ThermalReading reading;

  @override
  Widget build(BuildContext context) {
    final String value = reading.readingCelsius == null
        ? '—'
        : '${reading.readingCelsius!.toStringAsFixed(1)}°C';
    final List<String> thresholds = <String>[
      if (reading.upperCaution != null) 'caution ${reading.upperCaution!.toStringAsFixed(0)}',
      if (reading.upperCritical != null) 'crit ${reading.upperCritical!.toStringAsFixed(0)}',
    ];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(reading.name),
      subtitle: thresholds.isNotEmpty ? Text(thresholds.join(' / ')) : null,
      trailing: _HealthChip(health: reading.status.healthEnum, label: value),
    );
  }
}

/// A fan reading row.
class _FanTile extends StatelessWidget {
  /// Creates a [_FanTile].
  const _FanTile(this.reading);

  /// The fan reading to render.
  final FanReading reading;

  @override
  Widget build(BuildContext context) {
    final String value = reading.reading == null
        ? '—'
        : '${reading.reading!.toStringAsFixed(0)} RPM';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(reading.name),
      subtitle: reading.physicalContext != null
          ? Text(reading.physicalContext!)
          : null,
      trailing: _HealthChip(health: reading.status.healthEnum, label: value),
    );
  }
}

/// A generic sensor reading row.
class _SensorTile extends StatelessWidget {
  /// Creates a [_SensorTile].
  const _SensorTile(this.reading);

  /// The sensor reading to render.
  final SensorReading reading;

  @override
  Widget build(BuildContext context) {
    final String value = reading.reading == null
        ? '—'
        : '${reading.reading!.toStringAsFixed(2)} ${reading.readingUnits ?? ''}'.trim();
    final List<String> thresholds = reading.thresholds.entries
        .map((MapEntry<String, double> e) => '${e.key} ${e.value.toStringAsFixed(1)}')
        .toList();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(reading.name),
      subtitle: Text(<String>[
        if (reading.readingType != null) reading.readingType!,
        if (thresholds.isNotEmpty) thresholds.join(' / '),
      ].join(' · ')),
      trailing: _HealthChip(health: reading.status.healthEnum, label: value),
    );
  }
}

/// A compact health-tinted chip showing a reading value.
class _HealthChip extends StatelessWidget {
  /// Creates a [_HealthChip].
  const _HealthChip({required this.health, required this.label});

  /// Health used to pick the chip color.
  final Health health;

  /// The reading value rendered inside the chip.
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (health) {
      Health.ok => Colors.green,
      Health.warning => Colors.orange,
      Health.critical => Colors.red,
      Health.unknown => Colors.grey,
    };
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}
