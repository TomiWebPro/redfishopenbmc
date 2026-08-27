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
  _StubController() : super(service: KvmService(client: null, systemId: 'bmc1'));

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
  });
}
