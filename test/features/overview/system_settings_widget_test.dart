// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/core/theme/app_theme.dart';
import 'package:redfishopenbmc/features/overview/models/boot_settings.dart';
import 'package:redfishopenbmc/features/overview/models/system_overview.dart';
import 'package:redfishopenbmc/features/overview/overview_provider.dart';
import 'package:redfishopenbmc/features/overview/settings_controller.dart';
import 'package:redfishopenbmc/features/overview/settings_providers.dart';
import 'package:redfishopenbmc/features/overview/settings_service.dart';
import 'package:redfishopenbmc/features/overview/views/overview_view.dart';
import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';
import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';
import 'package:redfishopenbmc/features/systems/providers/profile_repository.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/session.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// A [SystemOverview] with a known, writable LED (exercises the LED setter).
SystemOverview ledSample() => SystemOverview(
      manufacturer: 'Acme',
      model: 'Server-9',
      powerState: PowerState.on,
      health: Health.ok,
      healthRollup: Health.ok,
      indicatorLed: IndicatorLed.lit,
      resourceUri: '/redfish/v1/Systems/system',
    );

SystemManager seededManager() {
  final SystemManager m = SystemManager(
    repository: InMemoryProfileRepository(),
    storage: InMemoryStorage(),
  );
  m.state = SystemState(
    systems: <String, SystemHandle>{
      'bmc1': SystemHandle(
        profile: const ConnectionProfile(id: 'bmc1', host: 'h'),
        status: ConnectionStatus.connected,
        session:
            Session(systemId: 'bmc1', token: 't', location: '', username: ''),
        features: const SystemFeatures(systemId: 'bmc1'),
        snapshot: SystemSnapshot(
          powerState: PowerState.on,
          resourceUri: '/redfish/v1/Systems/system',
        ),
      ),
    },
    selectedId: 'bmc1',
  );
  return m;
}

/// A fake [SystemSettingsService] with deterministic outcomes for widget
/// tests (mirrors the controller-test fake).
class _FakeSettingsService implements SystemSettingsService {
  _FakeSettingsService({
    this.bootResult,
    this.setLedError,
  });

  final BootSettings? bootResult;
  final RedfishException? setLedError;

  int setLedCount = 0;
  int setBootCount = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<BootSettings> fetchBootSettings() async {
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
    return <String, dynamic>{};
  }
}

const BootSettings bootSettings = BootSettings(
  target: 'Pxe',
  enabled: 'Once',
  allowableTargets: <String>['None', 'Pxe', 'Cd', 'Usb'],
);

void main() {
  group('SystemSettingsCard — Indicator LED setter (#016)', () {
    testWidgets('renders the writable chips under a known LED state',
        (tester) async {
      final _FakeSettingsService fake = _FakeSettingsService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemManagerProvider.overrideWith((ref) => seededManager()),
            overviewProvider.overrideWith(
              (ref, id) => Future<SystemOverview>.value(ledSample()),
            ),
            systemSettingsControllerProvider.overrideWith(
              (ref, id) => SystemSettingsController(service: fake),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: OverviewView(systemId: 'bmc1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lit'), findsWidgets); // read state + chip
      expect(find.text('Blinking'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
    });

    testWidgets('tapping a chip issues the PATCH via the controller',
        (tester) async {
      final _FakeSettingsService fake = _FakeSettingsService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemManagerProvider.overrideWith((ref) => seededManager()),
            overviewProvider.overrideWith(
              (ref, id) => Future<SystemOverview>.value(ledSample()),
            ),
            systemSettingsControllerProvider.overrideWith(
              (ref, id) => SystemSettingsController(service: fake),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: OverviewView(systemId: 'bmc1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Off'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Off'));
      await tester.pumpAndSettle();

      expect(fake.setLedCount, 1);
      expect(find.text('Off'), findsWidgets);
    });

    testWidgets('a PATCH failure surfaces the inline error, LED unchanged',
        (tester) async {
      final _FakeSettingsService fake = _FakeSettingsService(
        setLedError: const RedfishException(
          message: 'led denied',
          errorCode: 'Base.1.0.InsufficientPrivilege',
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemManagerProvider.overrideWith((ref) => seededManager()),
            overviewProvider.overrideWith(
              (ref, id) => Future<SystemOverview>.value(ledSample()),
            ),
            systemSettingsControllerProvider.overrideWith(
              (ref, id) => SystemSettingsController(service: fake),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: OverviewView(systemId: 'bmc1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Off'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Off'));
      await tester.pumpAndSettle();

      expect(fake.setLedCount, 1);
      expect(find.text('led denied'), findsOneWidget);
    });

    testWidgets('no overflow at 320 / 800 / 1300 px with the LED setter',
        (tester) async {
      for (final double width in <double>[320, 800, 1300]) {
        final _FakeSettingsService fake = _FakeSettingsService();
        await tester.binding.setSurfaceSize(Size(width, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              systemManagerProvider.overrideWith((ref) => seededManager()),
              overviewProvider.overrideWith(
                (ref, id) => Future<SystemOverview>.value(ledSample()),
              ),
              systemSettingsControllerProvider.overrideWith(
                (ref, id) => SystemSettingsController(service: fake),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(body: OverviewView(systemId: 'bmc1')),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'no overflow at $width');
        expect(find.byType(ChoiceChip), findsNWidgets(3));
      }
    });
  });

  group('SystemSettingsCard — Boot override (#016)', () {
    testWidgets('renders the dropdown + apply when an allow-list is advertised',
        (tester) async {
      final _FakeSettingsService fake =
          _FakeSettingsService(bootResult: bootSettings);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemManagerProvider.overrideWith((ref) => seededManager()),
            overviewProvider.overrideWith(
              (ref, id) => Future<SystemOverview>.value(ledSample()),
            ),
            systemSettingsControllerProvider.overrideWith(
              (ref, id) => SystemSettingsController(service: fake),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: OverviewView(systemId: 'bmc1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Boot source override target'), findsOneWidget);
      expect(find.text('Pxe'), findsOneWidget); // current target in the field
      expect(find.text('Apply boot override'), findsOneWidget);
    });

    testWidgets('Apply button meets the 48px minimum touch target (UI-2, a11y)',
        (tester) async {
      final _FakeSettingsService fake =
          _FakeSettingsService(bootResult: bootSettings);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemManagerProvider.overrideWith((ref) => seededManager()),
            overviewProvider.overrideWith(
              (ref, id) => Future<SystemOverview>.value(ledSample()),
            ),
            systemSettingsControllerProvider.overrideWith(
              (ref, id) => SystemSettingsController(service: fake),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: OverviewView(systemId: 'bmc1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Apply boot override'));
      await tester.pumpAndSettle();

      final Size size = tester.getSize(find.byType(FilledButton));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    });

    testWidgets(
        'applying a target issues setBootOverride through the controller',
        (tester) async {
      final _FakeSettingsService fake =
          _FakeSettingsService(bootResult: bootSettings);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemManagerProvider.overrideWith((ref) => seededManager()),
            overviewProvider.overrideWith(
              (ref, id) => Future<SystemOverview>.value(ledSample()),
            ),
            systemSettingsControllerProvider.overrideWith(
              (ref, id) => SystemSettingsController(service: fake),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: OverviewView(systemId: 'bmc1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Apply boot override'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply boot override'));
      await tester.pumpAndSettle();

      expect(fake.setBootCount, 1);
    });

    testWidgets('hidden (no placeholder) when the BMC advertises no allow-list',
        (tester) async {
      final _FakeSettingsService fake = _FakeSettingsService(
        bootResult: const BootSettings(target: 'Pxe', enabled: 'Once'),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemManagerProvider.overrideWith((ref) => seededManager()),
            overviewProvider.overrideWith(
              (ref, id) => Future<SystemOverview>.value(ledSample()),
            ),
            systemSettingsControllerProvider.overrideWith(
              (ref, id) => SystemSettingsController(service: fake),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: OverviewView(systemId: 'bmc1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Boot source override target'), findsNothing);
      expect(find.text('Apply boot override'), findsNothing);
    });

    testWidgets('no overflow at 320 / 800 / 1300 px with the boot card',
        (tester) async {
      for (final double width in <double>[320, 800, 1300]) {
        final _FakeSettingsService fake =
            _FakeSettingsService(bootResult: bootSettings);
        await tester.binding.setSurfaceSize(Size(width, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              systemManagerProvider.overrideWith((ref) => seededManager()),
              overviewProvider.overrideWith(
                (ref, id) => Future<SystemOverview>.value(ledSample()),
              ),
              systemSettingsControllerProvider.overrideWith(
                (ref, id) => SystemSettingsController(service: fake),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(body: OverviewView(systemId: 'bmc1')),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'no overflow at $width');
        expect(find.text('Apply boot override'), findsOneWidget);
      }
    });
  });
}
