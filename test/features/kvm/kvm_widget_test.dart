import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_controller.dart';
import 'package:redfishopenbmc/features/kvm/kvm_providers.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_view.dart';
import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// A [KvmController] whose [load] is a no-op and whose state can be pre-seeded
/// for widget tests (avoids hitting the network from the post-frame callback).
class _StubController extends KvmController {
  _StubController()
      : super(service: KvmService(client: null, systemId: 'bmc1'));

  @override
  Future<void> load() async {}
}

SystemHandle _handle({required bool kvm}) => SystemHandle(
      profile: const ConnectionProfile(id: 'bmc1', host: 'localhost'),
      features: SystemFeatures(systemId: 'bmc1', kvm: kvm),
    );

void main() {
  group('KvmView', () {
    testWidgets('renders nothing when the system has no KVM feature',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: false)),
          ],
          child: const MaterialApp(home: const KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();
      // The gate returns SizedBox.shrink → no console labels are rendered.
      expect(find.text('Graphical Console'), findsNothing);
    });

    testWidgets('renders a console card with its connect-type chip',
        (WidgetTester tester) async {
      final KvmController controller = _StubController()
        ..state = const KvmUiState(
          consoles: <KvmConsole>[
            KvmConsole(
              type: KvmConsoleType.graphical,
              managerId: 'BMC',
              connectTypesSupported: <String>['KVMIP'],
              serviceEnabled: true,
              sourceManagerUri: '/redfish/v1/Managers/BMC',
            ),
          ],
        );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: true)),
            kvmControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: const KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Graphical Console'), findsOneWidget);
      expect(find.text('KVMIP'), findsOneWidget);
      expect(find.text('Manager: BMC'), findsOneWidget);
      expect(find.text('Copy connect info'), findsOneWidget);
    });

    testWidgets(
        'console card announces the connect URI as one merged semantics '
        'node (UI-2)', (WidgetTester tester) async {
      final KvmController controller = _StubController()
        ..state = const KvmUiState(
          consoles: <KvmConsole>[
            KvmConsole(
              type: KvmConsoleType.graphical,
              managerId: 'BMC',
              connectTypesSupported: <String>['KVMIP'],
              serviceEnabled: true,
              connectUri: 'https://bmc.example.com:5288',
              sourceManagerUri: '/redfish/v1/Managers/BMC',
            ),
          ],
        );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: true)),
            kvmControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();

      // The label + value announce as ONE node, not two detached texts.
      expect(
        find.bySemanticsLabel('Connect URI: https://bmc.example.com:5288'),
        findsOneWidget,
        reason: 'UI-2: the connect-URI row announces one merged label',
      );
      // Visible texts are preserved for sighted users.
      expect(find.text('Connect URI:'), findsOneWidget);
      expect(find.text('https://bmc.example.com:5288'), findsOneWidget);
    });

    testWidgets(
        'console card header announces one merged semantics node — '
        'enabled (UI-2)', (WidgetTester tester) async {
      final KvmController controller = _StubController()
        ..state = const KvmUiState(
          consoles: <KvmConsole>[
            KvmConsole(
              type: KvmConsoleType.graphical,
              managerId: 'BMC',
              connectTypesSupported: <String>['KVMIP'],
              serviceEnabled: true,
              sourceManagerUri: '/redfish/v1/Managers/BMC',
            ),
          ],
        );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: true)),
            kvmControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: const KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();
      expect(
          find.bySemanticsLabel('Graphical Console, enabled'), findsOneWidget,
          reason: 'enabled console header announces one merged label');
    });

    testWidgets(
        'console card header announces one merged semantics node — '
        'disabled (UI-2)', (WidgetTester tester) async {
      final KvmController controller = _StubController()
        ..state = const KvmUiState(
          consoles: <KvmConsole>[
            KvmConsole(
              type: KvmConsoleType.serial,
              managerId: 'BMC',
              connectTypesSupported: <String>['SSH'],
              serviceEnabled: false,
              sourceManagerUri: '/redfish/v1/Managers/BMC',
            ),
          ],
        );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: true)),
            kvmControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: const KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Serial Console, disabled'), findsOneWidget,
          reason: 'disabled console header announces one merged label');
    });

    testWidgets(
        'view header announces one merged semantics node — title + subtitle '
        '(UI-2)', (WidgetTester tester) async {
      final KvmController controller = _StubController()
        ..state = const KvmUiState(
          consoles: <KvmConsole>[
            KvmConsole(
              type: KvmConsoleType.graphical,
              managerId: 'BMC',
              connectTypesSupported: <String>['KVMIP'],
              serviceEnabled: true,
              sourceManagerUri: '/redfish/v1/Managers/BMC',
            ),
          ],
        );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: true)),
            kvmControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: const KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Remote KVM / Consoles, consoles exposed by '
            'the system managers'),
        findsOneWidget,
        reason: 'the view title + subtitle announce as one merged node, not '
            'two detached text nodes',
      );
      // The visible texts are preserved for sighted users.
      expect(find.text('Remote KVM / Consoles'), findsOneWidget);
      expect(find.text('Consoles exposed by the system managers.'),
          findsOneWidget);
    });
  });

  group('KvmView — responsive layout (UI-3)', () {
    Future<void> pumpAtWidth(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final KvmController controller = _StubController()
        ..state = const KvmUiState(
          consoles: <KvmConsole>[
            KvmConsole(
              type: KvmConsoleType.graphical,
              managerId: 'BMC',
              connectTypesSupported: <String>['KVMIP'],
              serviceEnabled: true,
              sourceManagerUri: '/redfish/v1/Managers/BMC',
            ),
            KvmConsole(
              type: KvmConsoleType.serial,
              managerId: 'BMC',
              connectTypesSupported: <String>['SSH'],
              serviceEnabled: true,
              sourceManagerUri: '/redfish/v1/Managers/BMC',
            ),
          ],
        );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: true)),
            kvmControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final double width in <double>[320, 800, 1300]) {
      testWidgets('renders without overflow at ${width.toInt()} px',
          (tester) async {
        await pumpAtWidth(tester, width);
        expect(
          tester.takeException(),
          isNull,
          reason: 'KvmView must not overflow at $width px',
        );
        // Both console cards render at every breakpoint.
        expect(find.text('Graphical Console'), findsOneWidget);
        expect(find.text('Serial Console'), findsOneWidget);
      });
    }
  });
}
