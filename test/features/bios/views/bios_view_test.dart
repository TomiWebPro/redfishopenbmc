import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/features/bios/bios_controller.dart';
import 'package:redfishopenbmc/features/bios/bios_providers.dart';
import 'package:redfishopenbmc/features/bios/bios_service.dart';
import 'package:redfishopenbmc/features/bios/models/bios_models.dart';
import 'package:redfishopenbmc/features/bios/views/bios_view.dart';
import 'package:redfishopenbmc/features/systems/providers/profile_repository.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

SystemManager _seeded({bool bios = true}) {
  final SystemManager m = SystemManager(
    repository: InMemoryProfileRepository(),
    storage: InMemoryStorage(),
  );
  m.state = SystemState(
    systems: <String, SystemHandle>{
      'bmc1': SystemHandle(
        profile: const ConnectionProfile(id: 'bmc1', host: 'h'),
        status: ConnectionStatus.connected,
        features: SystemFeatures(systemId: 'bmc1', biosConfiguration: bios),
      ),
    },
    selectedId: 'bmc1',
  );
  return m;
}

ProviderScope _scope({
  required BiosUiState ui,
  bool bios = true,
}) {
  return ProviderScope(
    overrides: <Override>[
      systemManagerProvider.overrideWith((ref) => _seeded(bios: bios)),
      biosControllerProvider.overrideWith(
        (ref, id) => _FixedBiosController(ui),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: BiosView(systemId: 'bmc1')),
    ),
  );
}

class _FixedBiosController extends StateNotifier<BiosUiState>
    implements BiosController {
  _FixedBiosController(super.state);

  @override
  BiosService get service => BiosService(client: null, systemId: 'bmc1');

  @override
  Future<void> load() async {}

  @override
  Future<void> resetBios(BiosResource bios) async {}

  @override
  Future<void> applyPendingAttributes(
    BiosResource bios,
    Map<String, dynamic> attributes,
  ) async {}
}

void main() {
  group('BiosView (#028 read-only)', () {
    testWidgets('renders nothing when BIOS capability is absent',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _scope(ui: const BiosUiState(), bios: false),
      );
      await tester.pump();
      expect(find.byType(Card), findsNothing);
      expect(find.text('BIOS settings'), findsNothing);
    });

    testWidgets('shows loading state while fetching',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _scope(ui: const BiosUiState(loading: true)),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows current attributes and pending summary',
        (WidgetTester tester) async {
      const BiosUiState ui = BiosUiState(
        current: BiosResource(
          id: 'Bios',
          name: 'BIOS Configuration Current Settings',
          attributeRegistry: 'BiosAttributeRegistryP89.v1_0_0',
          attributes: BiosAttributes(<String, dynamic>{
            'AdminPhone': '',
            'BootMode': 'Uefi',
          }),
          settings: BiosSettingsAnnotation(
            etag: 'abc',
            settingsObjectUri: '/redfish/v1/Systems/1/Bios/Settings',
          ),
        ),
        pending: BiosPendingSettings(
          attributes: BiosAttributes(<String, dynamic>{
            'AdminPhone': '123',
            'BootMode': 'Uefi',
          }),
        ),
      );
      await tester.pumpWidget(_scope(ui: ui));
      await tester.pumpAndSettle();

      expect(find.text('BIOS settings'), findsOneWidget);
      expect(find.text('Attribute registry'), findsOneWidget);
      expect(find.text('BootMode'), findsWidgets);
      expect(find.text('Pending settings'), findsOneWidget);
      expect(find.textContaining('AdminPhone'), findsWidgets);
    });

    testWidgets('shows Reset BIOS action and disables it while resetting',
        (WidgetTester tester) async {
      const BiosUiState ui = BiosUiState(
        resetting: true,
        current: BiosResource(
          id: 'Bios',
          name: 'BIOS Configuration Current Settings',
          attributes: BiosAttributes(<String, dynamic>{'BootMode': 'Uefi'}),
          actions: BiosActions(
            resetBiosTarget:
                '/redfish/v1/Systems/1/Bios/Actions/Bios.ResetBios',
          ),
        ),
      );
      await tester.pumpWidget(_scope(ui: ui));
      await tester.pump();

      final Finder button =
          find.widgetWithText(FilledButton, 'Resetting BIOS…');
      expect(button, findsOneWidget);
      final FilledButton widget = tester.widget<FilledButton>(button);
      expect(widget.onPressed, isNull);
    });

    testWidgets('shows error with retry affordance',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _scope(ui: const BiosUiState(error: 'boom')),
      );
      await tester.pump();
      expect(find.text('Failed to load BIOS settings'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows apply-attribute form and disables it while applying',
        (WidgetTester tester) async {
      const BiosUiState ui = BiosUiState(
        applying: true,
        current: BiosResource(
          id: 'Bios',
          name: 'BIOS Configuration Current Settings',
          attributes: BiosAttributes(<String, dynamic>{
            'BootMode': 'Uefi',
            'QuietBoot': true,
          }),
          settings: BiosSettingsAnnotation(
            etag: 'abc',
            settingsObjectUri: '/redfish/v1/Systems/1/Bios/Settings',
          ),
        ),
      );
      await tester.pumpWidget(_scope(ui: ui));
      await tester.pump();

      expect(find.text('Apply attribute change'), findsOneWidget);
      expect(find.byKey(const Key('bios_attribute_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('bios_attribute_value')), findsOneWidget);
      final Finder button = find.byKey(const Key('bios_apply_attribute'));
      expect(button, findsOneWidget);
      final FilledButton widget = tester.widget<FilledButton>(button);
      expect(widget.onPressed, isNull);
      expect(find.text('Applying…'), findsOneWidget);
    });

    for (final double width in <double>[320, 800, 1300]) {
      testWidgets('has no overflow at ${width.toInt()} px',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const BiosUiState ui = BiosUiState(
          current: BiosResource(
            id: 'Bios',
            name: 'BIOS Configuration Current Settings',
            attributes: BiosAttributes(<String, dynamic>{
              'VeryLongAttributeNameForLayoutCheck': 'A long value string',
              'AnotherAttribute': 42,
            }),
          ),
        );
        await tester.pumpWidget(_scope(ui: ui));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
