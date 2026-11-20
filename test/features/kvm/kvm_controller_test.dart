// EP-S4 (issues #009 / #021): the async load state machine of KvmController is
// the single source of the gated KVM screen's loading / error / primary state,
// yet every widget test stubs the controller and no test drives it directly.
// This suite pins the full load() contract: in-flight loading, stale-error
// clearing, primary selection via KvmService.pickPrimary, primary clearing on an
// empty manager walk, fail-closed error capture for both RedfishException and
// generic failures, and the one-fetch-per-cycle in-flight guard.
//
// Pure unit tests with a scripted KvmService double — no live BMC, no URL opened,
// no WebView / protocol dependency, no TLS change (production TLS untouched).
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_controller.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

/// A [KvmService] double that returns a scripted console list, optionally
/// throws, and can gate the fetch with a [Completer] to observe in-flight state.
class _FakeKvmService extends KvmService {
  _FakeKvmService() : super(client: null, systemId: 'bmc1');

  /// Consoles returned by a successful fetch.
  List<KvmConsole> consoles = <KvmConsole>[];

  /// When non-null, thrown by a (non-gated) fetch.
  Object? errorToThrow;

  /// Optional gate: when set, fetch waits on it before returning/throwing.
  Completer<List<KvmConsole>>? gate;

  /// Number of fetchConsoles invocations.
  int fetchCalls = 0;

  @override
  Future<List<KvmConsole>> fetchConsoles() async {
    fetchCalls++;
    final Completer<List<KvmConsole>>? pending = gate;
    if (pending != null) await pending.future;
    final Object? failure = errorToThrow;
    if (failure != null) throw failure;
    return consoles;
  }
}

/// An enabled, control-safe HTTPS graphical console: the best "Primary" target.
const KvmConsole _secureGraphical = KvmConsole(
  type: KvmConsoleType.graphical,
  managerId: 'BMC',
  connectTypesSupported: <String>['KVMIP', 'HTML5'],
  serviceEnabled: true,
  connectUri: 'https://bmc.example/kvm',
  sourceManagerUri: '/redfish/v1/Managers/BMC',
);

/// An enabled external-client serial console: openable but not a secure target.
const KvmConsole _serial = KvmConsole(
  type: KvmConsoleType.serial,
  managerId: 'BMC2',
  connectTypesSupported: <String>['SSH', 'Telnet'],
  serviceEnabled: true,
  connectUri: 'ssh://bmc2.example',
  sourceManagerUri: '/redfish/v1/Managers/BMC2',
);

void main() {
  group('KvmController.load() async state machine (EP-S4, #009/#021)', () {
    test(
        'is loading only while the fetch is in flight, then publishes '
        'consoles, primary and a settled state', () async {
      final _FakeKvmService svc = _FakeKvmService()
        ..consoles = const <KvmConsole>[_serial, _secureGraphical];
      final KvmController controller = KvmController(service: svc);
      final Completer<List<KvmConsole>> gate = Completer<List<KvmConsole>>();
      svc.gate = gate;

      final Future<void> loading = controller.load();
      // Synchronous pre-await projection: loading is true, prior error cleared.
      expect(controller.state.loading, isTrue);
      expect(controller.state.consoles, isEmpty);
      expect(controller.state.primaryConsole, isNull);
      expect(controller.state.error, isNull);

      gate.complete(const <KvmConsole>[_serial, _secureGraphical]);
      await loading;

      expect(controller.state.loading, isFalse);
      expect(controller.state.consoles, hasLength(2));
      expect(
        controller.state.primaryConsole,
        same(KvmService.pickPrimary(const <KvmConsole>[
          _serial,
          _secureGraphical,
        ])),
      );
      expect(controller.state.error, isNull);
    });

    test('selects the primary via KvmService.pickPrimary on success', () async {
      final _FakeKvmService svc = _FakeKvmService()
        ..consoles = const <KvmConsole>[_secureGraphical, _serial];
      final KvmController controller = KvmController(service: svc);

      await controller.load();

      expect(controller.state.primaryConsole, same(_secureGraphical));
      expect(
        controller.state.primaryConsole,
        same(KvmService.pickPrimary(svc.consoles)),
      );
    });

    test('clears the primary and consoles when the manager walk is empty',
        () async {
      final _FakeKvmService svc = _FakeKvmService()
        ..consoles = const <KvmConsole>[_secureGraphical];
      final KvmController controller = KvmController(service: svc);

      await controller.load();
      expect(controller.state.primaryConsole, same(_secureGraphical));

      svc.consoles = const <KvmConsole>[];
      await controller.load();

      expect(controller.state.consoles, isEmpty);
      expect(controller.state.primaryConsole, isNull);
      expect(controller.state.loading, isFalse);
      expect(controller.state.error, isNull);
    });

    test('clears a prior error on a subsequent successful load', () async {
      final _FakeKvmService svc = _FakeKvmService()
        ..errorToThrow =
            const RedfishException(message: 'first attempt failed');
      final KvmController controller = KvmController(service: svc);

      await controller.load();
      expect(controller.state.error, 'first attempt failed');

      svc.errorToThrow = null;
      svc.consoles = const <KvmConsole>[_secureGraphical];
      await controller.load();

      expect(controller.state.error, isNull);
      expect(controller.state.consoles, hasLength(1));
      expect(controller.state.primaryConsole, same(_secureGraphical));
    });

    test(
        'captures a RedfishException message with loading cleared and '
        'primary cleared instead of throwing', () async {
      final _FakeKvmService svc = _FakeKvmService()
        ..consoles = const <KvmConsole>[_secureGraphical];
      final KvmController controller = KvmController(service: svc);
      await controller.load();
      expect(controller.state.primaryConsole, same(_secureGraphical));

      svc.errorToThrow = const RedfishException(
        message: 'HTTP 401: session expired',
        statusCode: 401,
      );

      await controller.load(); // must not throw

      expect(controller.state.loading, isFalse);
      expect(controller.state.error, 'HTTP 401: session expired');
      expect(controller.state.primaryConsole, isNull);
    });

    test('captures a generic exception into error without throwing', () async {
      final _FakeKvmService svc = _FakeKvmService()
        ..consoles = const <KvmConsole>[_secureGraphical];
      final KvmController controller = KvmController(service: svc);
      await controller.load();

      svc.errorToThrow = StateError('unexpected wire failure');
      await controller.load(); // must not throw

      expect(controller.state.loading, isFalse);
      expect(controller.state.error, contains('unexpected wire failure'));
      expect(controller.state.primaryConsole, isNull);
    });

    test(
        'a second load() while already loading is a no-op (one fetch per '
        'cycle)', () async {
      final _FakeKvmService svc = _FakeKvmService()
        ..consoles = const <KvmConsole>[_secureGraphical];
      final KvmController controller = KvmController(service: svc);
      final Completer<List<KvmConsole>> gate = Completer<List<KvmConsole>>();
      svc.gate = gate;

      final Future<void> first = controller.load();
      expect(controller.state.loading, isTrue);

      await controller.load(); // arrives mid-flight: must not start a 2nd fetch
      expect(svc.fetchCalls, 1);
      expect(controller.state.loading, isTrue);

      gate.complete(const <KvmConsole>[_secureGraphical]);
      await first;

      expect(svc.fetchCalls, 1);
      expect(controller.state.loading, isFalse);
      expect(controller.state.consoles, hasLength(1));
      expect(controller.state.primaryConsole, same(_secureGraphical));
    });

    test('recovers after an in-flight no-op: a later load re-fetches',
        () async {
      final _FakeKvmService svc = _FakeKvmService()
        ..consoles = const <KvmConsole>[_secureGraphical];
      final KvmController controller = KvmController(service: svc);
      final Completer<List<KvmConsole>> gate = Completer<List<KvmConsole>>();
      svc.gate = gate;

      final Future<void> first = controller.load();
      await controller.load(); // no-op while gated
      expect(svc.fetchCalls, 1);

      gate.complete(const <KvmConsole>[_secureGraphical]);
      await first;
      svc.gate = null;

      await controller.load(); // new cycle after settle: fetches again
      expect(svc.fetchCalls, 2);
      expect(controller.state.loading, isFalse);
      expect(controller.state.primaryConsole, same(_secureGraphical));
    });
  });
}
