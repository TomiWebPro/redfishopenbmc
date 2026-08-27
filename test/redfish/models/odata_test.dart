import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/redfish/models/odata.dart';

void main() {
  group('ODataResource', () {
    test('reads @odata.id / type / context', () {
      final ODataResource r = const ODataResource(<String, dynamic>{
        '@odata.id': '/redfish/v1/Systems/1',
        '@odata.type': '#ComputerSystem.v1_20_0.ComputerSystem',
        '@odata.context': r'/redfish/v1/$metadata#ComputerSystem',
      });
      expect(r.id, '/redfish/v1/Systems/1');
      expect(r.type, '#ComputerSystem.v1_20_0.ComputerSystem');
      expect(r.context, '/redfish/v1/\$metadata#ComputerSystem');
    });

    test('isCollection true when Members present', () {
      expect(
        const ODataResource(<String, dynamic>{'Members': <dynamic>[]}).isCollection,
        isTrue,
      );
      expect(
        const ODataResource(<String, dynamic>{'Id': 'x'}).isCollection,
        isFalse,
      );
    });

    test('memberIds extracts @odata.id from members (map or string)', () {
      final ODataResource r = const ODataResource(<String, dynamic>{
        'Members': <dynamic>[
          <String, dynamic>{'@odata.id': '/a'},
          '/b',
        ],
      });
      expect(r.memberIds(), <String>['/a', '/b']);
    });

    test('actionTarget resolves a target by action name', () {
      final ODataResource r = const ODataResource(<String, dynamic>{
        'Actions': <String, dynamic>{
          '#ComputerSystem.Reset': <String, dynamic>{'target': '/reset'},
        },
      });
      expect(r.actionTarget('#ComputerSystem.Reset'), '/reset');
      expect(r.actionTarget('#Manager.Reset'), isNull);
    });

    test('linkUris handles bare-string and {@odata.id} link shapes', () {
      final ODataResource r = const ODataResource(<String, dynamic>{
        'Thermal': <String, dynamic>{'@odata.id': '/t'},
        'Sensors': '/s',
      });
      expect(r.linkUris(<String>['Thermal', 'Sensors']), <String>['/t', '/s']);
    });

    test('isType ignores collection suffixes but matches concrete types', () {
      expect(
        const ODataResource(<String, dynamic>{
          '@odata.type': '#ComputerSystem.v1_20_0.ComputerSystem',
        }).isType('computersystem'),
        isTrue,
      );
      expect(
        const ODataResource(<String, dynamic>{
          '@odata.type': '#ComputerSystemCollection.ComputerSystemCollection',
        }).isType('computersystem'),
        isFalse,
      );
      expect(
        const ODataResource(<String, dynamic>{
          '@odata.type': '#Manager.v1_16_0.Manager',
        }).isType('manager'),
        isTrue,
      );
      expect(
        const ODataResource(<String, dynamic>{
          '@odata.type': '#Chassis.v1_24_0.Chassis',
        }).isType('chassis'),
        isTrue,
      );
    });
  });

  group('ODataLink', () {
    test('fromResource builds from a resource map', () {
      final ODataLink? link = ODataLink.fromResource(<String, dynamic>{
        '@odata.id': '/redfish/v1/X',
        '@odata.type': '#Thing.v1_0_0.Thing',
      });
      expect(link, isNotNull);
      expect(link!.id, '/redfish/v1/X');
      expect(link.type, '#Thing.v1_0_0.Thing');
    });

    test('fromResource returns null without @odata.id', () {
      expect(ODataLink.fromResource(<String, dynamic>{'Id': 'x'}), isNull);
    });
  });
}
