// EP-U11 (issue #009 / #021): the capability card and the per-console card are
// two operator decision surfaces for the SAME Redfish manager, built from two
// independent model projections (`KvmCapability.fromManager` /
// `KvmConsole.fromManager`). The model-level RemoteConsole / explicit-disable
// agreement is pinned in `kvm_capability_test.dart`, but nothing pinned that the
// two RENDERED cards still agree: a one-sided view edit could announce
// "KVM not supported" / show the BMC-disabled helper on the capability card
// while the peer card offers an enabled, launchable console (or vice versa).
// This guard builds BOTH cards in one tree straight from the same manager body
// and fails closed on any such divergence, at 320 / 800 / 1300 px.
//
// Display-only, dependency-free and TLS-safe: no URL is opened, no WebView or
// protocol dependency is imported and production TLS is untouched.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_controller.dart';
import 'package:redfishopenbmc/features/kvm/kvm_providers.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_capability_card.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_transport_notice.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

class _StubController extends KvmController {
  _StubController()
      : super(service: KvmService(client: null, systemId: 'bmc1'));

  @override
  Future<void> load() async {}
}

SystemHandle _handle() => const SystemHandle(
      profile: ConnectionProfile(id: 'bmc1', host: 'localhost'),
      features: SystemFeatures(systemId: 'bmc1', kvm: true),
    );

/// Builds the real `KvmView`, which renders the capability card and every
/// per-console card from the SAME manager projection used by production. Only
/// the upstream data providers are overridden — both card implementations run
/// for real, so a one-sided rendering change is caught in one tree.
Future<void> _pumpBothCards(
  WidgetTester tester, {
  required Map<String, dynamic> managerBody,
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final List<KvmConsole> consoles =
      KvmConsole.fromManager(managerBody, managerId: 'BMC');
  final KvmCapability capability =
      KvmCapability.fromManager(managerBody, managerId: 'BMC');
  final KvmController controller = _StubController()
    ..state = KvmUiState(consoles: consoles);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(_handle()),
        kvmControllerProvider.overrideWith((ref, id) => controller),
        kvmCapabilitiesProvider.overrideWith(
          (ref, id) =>
              Future<List<KvmCapability>>.value(<KvmCapability>[capability]),
        ),
      ],
      child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
    ),
  );
  await tester.pumpAndSettle();
}

/// The per-console card is the Card ancestor of its merged manager label.
Finder _consoleCard() => find.ancestor(
      of: find.bySemanticsLabel('Manager: BMC'),
      matching: find.byType(Card),
    );

void main() {
  group('EP-U11 cross-surface card agreement (#009/#021)', () {
    for (final double width in <double>[320, 800, 1300]) {
      testWidgets(
        'enabled RemoteConsole-only manager: supported on the capability '
        'card AND launchable on the console card at ${width.toStringAsFixed(0)} px',
        (WidgetTester tester) async {
          await _pumpBothCards(
            tester,
            width: width,
            managerBody: <String, dynamic>{
              '@odata.id': '/redfish/v1/Managers/BMC',
              'RemoteConsole': <String, dynamic>{
                'ServiceEnabled': true,
                'ConnectTypesSupported': <dynamic>['HTML5'],
                'MaxConcurrentSessions': 2,
                'ConnectUri': 'https://bmc.example/html5',
              },
            },
          );

          final Finder capability = find.byType(KvmCapabilityCard);
          final Finder consoleCard = _consoleCard();
          expect(capability, findsOneWidget,
              reason: 'capability card rendered at $width px');
          expect(consoleCard, findsOneWidget,
              reason: 'per-console card rendered at $width px');

          // Capability side: supported + enabled, no disabled helper.
          expect(
            find.descendant(of: capability, matching: find.text('Supported')),
            findsOneWidget,
            reason:
                'capability card must advertise a supported console at $width px',
          );
          expect(
            find.descendant(of: capability, matching: find.text('Enabled')),
            findsOneWidget,
          );
          expect(
            find.bySemanticsLabel(
                'Manager capability BMC, enabled, KVM supported'),
            findsOneWidget,
            reason:
                'merged capability announcement agrees with the console card at $width px',
          );
          expect(find.text(kvmDisabledOnBmcNotice), findsNothing,
              reason:
                  'an enabled manager must never show the BMC-disabled helper at $width px');

          // Console side: the same manager is enabled and launchable.
          expect(
            find.descendant(
                of: consoleCard, matching: find.text('Open console')),
            findsOneWidget,
            reason:
                'peer console card must offer launch when capability says supported at $width px',
          );
          expect(
            find.bySemanticsLabel('Connect URI: https://bmc.example/html5'),
            findsOneWidget,
          );
          // Both surfaces resolve the SAME endpoint for the SAME manager.
          expect(find.text('https://bmc.example/html5'), findsNWidgets(2),
              reason:
                  'capability resolved URI and console connect URI must agree at $width px');
          expect(tester.takeException(), isNull,
              reason: 'both cards must render without overflow at $width px');
        },
      );

      testWidgets(
        'BMC-disabled manager: unsupported on the capability card AND '
        'non-launchable on the console card at ${width.toStringAsFixed(0)} px',
        (WidgetTester tester) async {
          await _pumpBothCards(
            tester,
            width: width,
            managerBody: <String, dynamic>{
              '@odata.id': '/redfish/v1/Managers/BMC',
              'GraphicalConsole': <String, dynamic>{
                'ServiceEnabled': false,
                'ConnectTypesSupported': <dynamic>['KVMIP'],
                'ConnectUri': 'https://bmc.example/kvm',
              },
            },
          );

          final Finder capability = find.byType(KvmCapabilityCard);
          final Finder consoleCard = _consoleCard();
          expect(capability, findsOneWidget);
          expect(consoleCard, findsOneWidget);

          // Capability side: not supported + disabled helper.
          expect(
            find.bySemanticsLabel(
                'Manager capability BMC, disabled, KVM not supported'),
            findsOneWidget,
            reason:
                'merged capability announcement reflects the disabled manager at $width px',
          );
          expect(
            find.descendant(
              of: capability,
              matching: find.text(kvmDisabledOnBmcNotice),
            ),
            findsOneWidget,
            reason:
                'capability card must show the BMC-disabled helper at $width px',
          );
          expect(
            find.descendant(of: capability, matching: find.text('Supported')),
            findsNothing,
            reason:
                'a disabled manager must never advertise the Supported chip at $width px',
          );

          // Console side: same manager is non-launchable with shared guidance.
          final String disabledStatus =
              kvmLaunchStatusText(KvmLaunchStrategy.disabled);
          expect(
            find.descendant(
                of: consoleCard, matching: find.text('Open console')),
            findsNothing,
            reason:
                'peer console card must not offer launch when capability is disabled at $width px',
          );
          expect(
            find.descendant(
                of: consoleCard, matching: find.text(disabledStatus)),
            findsOneWidget,
            reason:
                'console card must show the shared enable-on-BMC status at $width px',
          );
          expect(
            find.bySemanticsLabel(disabledStatus),
            findsOneWidget,
            reason: 'a11y: visible text == announced label at $width px',
          );
          expect(tester.takeException(), isNull,
              reason: 'both cards must render without overflow at $width px');
        },
      );
    }
  });
}
