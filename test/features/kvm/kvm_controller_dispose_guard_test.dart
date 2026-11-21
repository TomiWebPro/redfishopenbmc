// EP-S4 closeout (issues #009 / #021): `KvmController` documents that `load()`
// checks `mounted` after every `await` so a fetch that settles after the
// notifier was disposed cannot write state on a dead notifier. The EP-S4
// state-machine suite drives all three outcome branches (success / Redfish
// failure / generic failure) but never disposes the controller mid-flight, so
// dropping any of those three `if (mounted)` guards would let a post-dispose
// `state =` throw a `StateError` out of the fire-and-forget load future and
// stay GREEN. These tests dispose the controller while the fetch is gated and
// then settle it, pinning that each branch stays crash-free.
//
// Pure unit tests with a scripted KvmService double: no live BMC, no URL
// opened, no WebView / protocol dependency, no TLS change (production TLS
// untouched).
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_controller.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

/// A [KvmService] whose fetch waits on [gate], then either throws [errorToThrow]
/// or returns a single secure console. Lets the test dispose the notifier while
/// the fetch is still in flight, then settle it on demand.
class _GatedKvmService extends KvmService {
  _GatedKvmService() : super(client: null, systemId: 'bmc1');

  final Completer<List<KvmConsole>> gate = Completer<List<KvmConsole>>();
  Object? errorToThrow;

  @override
  Future<List<KvmConsole>> fetchConsoles() async {
    await gate.future;
    final Object? failure = errorToThrow;
    if (failure != null) throw failure;
    return const <KvmConsole>[_secureGraphical];
  }
}

/// An enabled, control-safe HTTPS graphical console (a valid success payload).
const KvmConsole _secureGraphical = KvmConsole(
  type: KvmConsoleType.graphical,
  managerId: 'BMC',
  connectTypesSupported: <String>['KVMIP', 'HTML5'],
  serviceEnabled: true,
  connectUri: 'https://bmc.example/kvm',
  sourceManagerUri: '/redfish/v1/Managers/BMC',
);

void main() {
  group('KvmController.load() dispose-after-async-gap guard (#009/#021)', () {
    test('a successful fetch settling after dispose does not throw', () async {
      final _GatedKvmService svc = _GatedKvmService();
      final KvmController controller = KvmController(service: svc);

      final Future<void> loading = controller.load();
      expect(controller.mounted, isTrue);
      expect(controller.state.loading, isTrue);

      controller.dispose(); // mid-flight: the fetch is still gated
      expect(controller.mounted, isFalse);

      svc.gate.complete(const <KvmConsole>[_secureGraphical]);
      await loading; // must settle without throwing on the dead notifier
    });

    test('a RedfishException settling after dispose does not throw', () async {
      final _GatedKvmService svc = _GatedKvmService()
        ..errorToThrow = const RedfishException(
          message: 'HTTP 401: session expired',
          statusCode: 401,
        );
      final KvmController controller = KvmController(service: svc);

      final Future<void> loading = controller.load();
      controller.dispose(); // mid-flight
      expect(controller.mounted, isFalse);

      svc.gate.complete(const <KvmConsole>[]);
      await loading; // the catch branch must honour `mounted` too
    });

    test('a generic error settling after dispose does not throw', () async {
      final _GatedKvmService svc = _GatedKvmService()
        ..errorToThrow = StateError('unexpected wire failure');
      final KvmController controller = KvmController(service: svc);

      final Future<void> loading = controller.load();
      controller.dispose(); // mid-flight
      expect(controller.mounted, isFalse);

      svc.gate.complete(const <KvmConsole>[]);
      await loading; // the generic catch branch must honour `mounted` too
    });
  });
}
