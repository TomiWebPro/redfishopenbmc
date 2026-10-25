import 'package:flutter_test/flutter_test.dart';

import 'package:redfishopenbmc/features/overview/models/boot_settings.dart';
import 'package:redfishopenbmc/features/overview/models/system_overview.dart';
import 'package:redfishopenbmc/features/overview/settings_controller.dart';
import 'package:redfishopenbmc/features/overview/settings_service.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

class _FakeSettingsService implements SystemSettingsService {
  _FakeSettingsService({
    this.bootResult,
    this.setLedError,
    this.setBootError,
  });

  final BootSettings? bootResult;
  final RedfishException? setLedError;
  final RedfishException? setBootError;

  int fetchCount = 0;
  int setLedCount = 0;
  int setBootCount = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<BootSettings> fetchBootSettings() async {
    fetchCount++;
    if (bootResult == null) {
      throw const RedfishException(
        message: 'read failed',
        errorCode: 'Base.1.0.InternalError',
      );
    }
    return bootResult!;
  }

  @override
  Future<Map<String, dynamic>> setIndicatorLed(IndicatorLed value) async {
    setLedCount++;
    if (setLedError != null) throw setLedError!;
    return <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> setBootOverride({
    required String target,
    String enabled = 'Once',
  }) async {
    setBootCount++;
    if (setBootError != null) throw setBootError!;
    return <String, dynamic>{};
  }
}

void main() {
  const BootSettings boot = BootSettings(
    target: 'Pxe',
    enabled: 'Once',
    allowableTargets: <String>['None', 'Pxe', 'Cd', 'Usb'],
  );

  group('SystemSettingsController — loadBootSettings', () {
    test('loads settings into the state and clears errors', () async {
      final _FakeSettingsService service =
          _FakeSettingsService(bootResult: boot);
      final SystemSettingsController c =
          SystemSettingsController(service: service);
      await c.loadBootSettings();
      expect(c.state.bootSettings?.target, 'Pxe');
      expect(c.state.error, isNull);
      expect(service.fetchCount, 1);
      c.dispose();
    });

    test('records a friendly error on read failure, keeps prior settings',
        () async {
      final _FakeSettingsService failing =
          _FakeSettingsService(bootResult: null);
      final SystemSettingsController c =
          SystemSettingsController(service: failing);
      await c.loadBootSettings();
      expect(c.state.error, 'read failed');
      expect(c.state.bootSettings, isNull);
      c.dispose();
    });
  });

  group('SystemSettingsController — setIndicatorLed', () {
    test('applies the value optimistically and clears the busy flag', () async {
      final _FakeSettingsService service = _FakeSettingsService();
      final SystemSettingsController c =
          SystemSettingsController(service: service);
      final Future<void> future = c.setIndicatorLed(IndicatorLed.blinking);
      expect(c.state.actionInFlight, isTrue);
      await future;
      expect(c.state.actionInFlight, isFalse);
      expect(c.state.indicatorLed, IndicatorLed.blinking);
      expect(c.state.error, isNull);
      expect(service.setLedCount, 1);
      c.dispose();
    });

    test('records the error on failure and leaves the LED unchanged', () async {
      final _FakeSettingsService service = _FakeSettingsService(
        setLedError: const RedfishException(
          message: 'led denied',
          errorCode: 'Base.1.0.InsufficientPrivilege',
        ),
      );
      final SystemSettingsController c =
          SystemSettingsController(service: service);
      await c.setIndicatorLed(IndicatorLed.off);
      expect(c.state.actionInFlight, isFalse);
      expect(c.state.error, 'led denied');
      expect(c.state.indicatorLed, isNull);
      c.dispose();
    });
  });

  group('SystemSettingsController — setBootOverride', () {
    test('applies the override then refreshes the boot settings', () async {
      final _FakeSettingsService service =
          _FakeSettingsService(bootResult: boot);
      final SystemSettingsController c =
          SystemSettingsController(service: service);
      final Future<void> future =
          c.setBootOverride(target: 'Cd', enabled: 'Once');
      expect(c.state.actionInFlight, isTrue);
      await future;
      expect(c.state.actionInFlight, isFalse);
      expect(c.state.error, isNull);
      expect(service.setBootCount, 1);
      expect(
        service.fetchCount,
        1,
        reason: 'a successful apply refreshes the shown settings',
      );
      expect(
        c.state.bootSettings?.target,
        'Pxe',
        reason: 'refresh re-reads the current target',
      );
      c.dispose();
    });

    test('records the error on failure without a refresh', () async {
      final _FakeSettingsService service = _FakeSettingsService(
        bootResult: boot,
        setBootError: const RedfishException(
          message: 'target rejected',
          statusCode: 400,
          errorCode: 'Base.1.0.PropertyValueNotInList',
        ),
      );
      final SystemSettingsController c =
          SystemSettingsController(service: service);
      await c.setBootOverride(target: 'Bogus');
      expect(c.state.error, 'target rejected');
      expect(c.state.actionInFlight, isFalse);
      expect(service.fetchCount, 0);
      c.dispose();
    });
  });
}
