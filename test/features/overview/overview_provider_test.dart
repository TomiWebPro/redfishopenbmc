// ignore_for_file: prefer_const_constructors
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/core/theme/breakpoints.dart';
import 'package:redfishopenbmc/features/overview/models/system_overview.dart';
import 'package:redfishopenbmc/features/overview/overview_provider.dart';
import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';
import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';
import 'package:redfishopenbmc/features/systems/providers/profile_repository.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/session.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Matches mock routes by path, ignoring host (mirrors the #002/#005 helpers).
class _PathMatcher extends HttpRequestMatcher {
  const _PathMatcher();

  @override
  bool matches(RequestOptions ongoingRequest, Request matcher) {
    final dynamic route = matcher.route;
    final String routeStr = route is String ? route : route.toString();
    final String path = ongoingRequest.path;
    if (path == routeStr) return true;
    final Uri? uri = Uri.tryParse(path);
    if (uri != null && uri.path == routeStr) return true;
    return path.endsWith(routeStr);
  }
}

RedfishClient clientWithAdapter(DioAdapter adapter) => RedfishClient(
      profile: const ConnectionProfile(id: 'bmc1', host: 'bmc1.local'),
      dio: adapter.dio,
    );

/// Builds a [SystemManager] pre-seeded with a connected [systemId] whose
/// [RedfishClient] is [client] (typically a mocked Dio), so [overviewProvider]
/// can be exercised without a real BMC.
SystemManager managerWithClient(RedfishClient client) {
  final SystemManager m = SystemManager(
    repository: InMemoryProfileRepository(),
    storage: InMemoryStorage(),
  );
  m.state = SystemState(
    systems: <String, SystemHandle>{
      'bmc1': SystemHandle(
        profile: const ConnectionProfile(id: 'bmc1', host: 'bmc1.local'),
        status: ConnectionStatus.connected,
        session: Session(
          systemId: 'bmc1',
          token: 't',
          location: '',
          username: '',
        ),
        client: client,
        features: const SystemFeatures(systemId: 'bmc1'),
        snapshot: SystemSnapshot(
          health: Health.unknown,
          resourceUri: '/redfish/v1/Systems/system',
        ),
      ),
    },
    selectedId: 'bmc1',
  );
  return m;
}

Future<SystemOverview> fetchOverview(SystemManager manager) async {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      systemManagerProvider.overrideWith((ref) => manager),
    ],
  );
  addTearDown(container.dispose);
  return container.read(overviewProvider('bmc1').future);
}

void main() {
  group('SystemOverview.fromRedfish — model', () {
    test('parses a fully-populated ComputerSystem', () {
      final SystemOverview o = SystemOverview.fromRedfish(<String, dynamic>{
        'Manufacturer': 'OpenBMC',
        'Model': 'Rainier',
        'SKU': 'SKU1',
        'SerialNumber': 'SN1',
        'PartNumber': 'PN1',
        'BiosVersion': '1.0',
        'PowerState': 'On',
        'Status': <String, dynamic>{'Health': 'OK'},
        'ProcessorSummary': <String, dynamic>{
          'Count': 2,
          'Model': 'P9',
        },
        'MemorySummary': <String, dynamic>{'TotalSystemMemoryGiB': 64},
        'IndicatorLED': 'Lit',
      });
      expect(o.manufacturer, 'OpenBMC');
      expect(o.model, 'Rainier');
      expect(o.sku, 'SKU1');
      expect(o.serialNumber, 'SN1');
      expect(o.partNumber, 'PN1');
      expect(o.biosVersion, '1.0');
      expect(o.powerState, PowerState.on);
      expect(o.health, Health.ok);
      expect(o.processorSummary.count, 2);
      expect(o.processorSummary.model, 'P9');
      expect(o.memorySummary.totalGiB, 64);
      expect(o.indicatorLed, IndicatorLed.lit);
      expect(o.hasProcessors, isTrue);
      expect(o.hasMemory, isTrue);
    });

    test('falls back from Health to HealthRollup then Unknown', () {
      final SystemOverview o = SystemOverview.fromRedfish(<String, dynamic>{
        'Status': <String, dynamic>{'Health': '', 'HealthRollup': 'Critical'},
      });
      expect(o.health, Health.critical);
      expect(o.healthRollup, Health.critical);

      final SystemOverview missing =
          SystemOverview.fromRedfish(<String, dynamic>{});
      expect(missing.health, Health.unknown);
      expect(missing.healthRollup, Health.unknown);
    });

    test('tolerates missing optional blocks (OpenBMC QEMU)', () {
      final SystemOverview o =
          SystemOverview.fromRedfish(<String, dynamic>{'Id': 'system'});
      expect(o.manufacturer, isNull);
      expect(o.processorSummary.count, isNull);
      expect(o.memorySummary.totalGiB, isNull);
      expect(o.indicatorLed, IndicatorLed.unknown);
      expect(o.hasProcessors, isFalse);
      expect(o.hasMemory, isFalse);
    });

    test('parses numeric/typed memory and indicator LED variants', () {
      expect(
        MemorySummary.fromJson(<String, dynamic>{'TotalSystemMemoryGiB': 8})
            .totalGiB,
        8,
      );
      expect(
        MemorySummary.fromJson(
          <String, dynamic>{'TotalSystemMemoryGiB': '16.5'},
        ).totalGiB,
        16.5,
      );
      expect(
        ProcessorSummary.fromJson(
          <String, dynamic>{'Count': '4', 'Model': 'X'},
        ).count,
        4,
      );
      expect(IndicatorLed.fromRedfish('Blinking'), IndicatorLed.blinking);
      expect(IndicatorLed.fromRedfish(null), IndicatorLed.unknown);
    });

    test('fromSystemJson derives leading temperature from the thermal body',
        () {
      final SystemOverview o = SystemOverview.fromSystemJson(
        <String, dynamic>{
          'Manufacturer': 'Acme',
          'Status': <String, dynamic>{'Health': 'OK'},
        },
        thermalJson: <String, dynamic>{
          'Temperatures': <Map<String, dynamic>>[
            <String, dynamic>{'ReadingCelsius': 38.5},
          ],
        },
        resourceUri: '/redfish/v1/Systems/system',
      );
      expect(o.manufacturer, 'Acme');
      expect(o.health, Health.ok);
      expect(o.leadingTemperatureCelsius, 38.5);
      expect(o.resourceUri, '/redfish/v1/Systems/system');
    });
  });

  group('SystemOverview — toJson / copyWith / helpers', () {
    test('toJson emits the documented envelope fields', () {
      final SystemOverview o = SystemOverview.fromRedfish(
        <String, dynamic>{
          'Manufacturer': 'A',
          'Model': 'M',
          'PowerState': 'On',
          'Status': <String, dynamic>{'Health': 'OK'},
        },
        leadingTemperatureCelsius: 40,
        resourceUri: '/x',
      );
      final Map<String, dynamic> json = o.toJson();
      expect(json['manufacturer'], 'A');
      expect(json['model'], 'M');
      expect(json['health'], 'ok');
      expect(json['power_state'], 'on');
      expect(json['leading_temperature_celsius'], 40);
      expect(json['resource_uri'], '/x');
      expect(json['indicator_led'], 'unknown');
    });

    test('copyWith overrides only the provided fields', () {
      const SystemOverview o = SystemOverview(manufacturer: 'A');
      expect(o.copyWith(model: 'M').model, 'M');
      expect(o.copyWith(model: 'M').manufacturer, 'A');
    });

    test('IndicatorLed.label covers every value', () {
      expect(IndicatorLed.lit.label, 'Lit');
      expect(IndicatorLed.off.label, 'Off');
      expect(IndicatorLed.blinking.label, 'Blinking');
      expect(IndicatorLed.unknown.label, 'Unknown');
    });

    test('hasProcessors / hasMemory reflect presence', () {
      expect(const SystemOverview().hasProcessors, isFalse);
      expect(
        const SystemOverview(processorSummary: ProcessorSummary(count: 1))
            .hasProcessors,
        isTrue,
      );
      expect(const SystemOverview().hasMemory, isFalse);
      expect(
        const SystemOverview(memorySummary: MemorySummary(totalGiB: 8))
            .hasMemory,
        isTrue,
      );
      expect(const SystemOverview(leadingTemperatureCelsius: 1).hasTemperature, isTrue);
    });
  });

  group('OverviewGridBreakpoints', () {
    test('maps widths to 1/2/3 columns', () {
      expect(OverviewGridBreakpoints.columnsForWidth(400), 1);
      expect(OverviewGridBreakpoints.columnsForWidth(599), 1);
      expect(OverviewGridBreakpoints.columnsForWidth(600), 2);
      expect(OverviewGridBreakpoints.columnsForWidth(1023), 2);
      expect(OverviewGridBreakpoints.columnsForWidth(1024), 3);
      expect(OverviewGridBreakpoints.columnsForWidth(1600), 3);
      expect(overviewColumnsForWidth(400), 1);
      expect(overviewColumnsForWidth(1400), 3);
    });

    test('classifies breakpoints by width', () {
      expect(OverviewGridBreakpoints.forWidth(400), OverviewBreakpoint.mobile);
      expect(OverviewGridBreakpoints.forWidth(600), OverviewBreakpoint.tablet);
      expect(OverviewGridBreakpoints.forWidth(1024), OverviewBreakpoint.desktop);
    });
  });

  group('overviewProvider — hydration', () {
    test('walks /Systems, reads the ComputerSystem and linked chassis thermal',
        () async {
      final DioAdapter adapter = DioAdapter(
        dio: Dio(BaseOptions(baseUrl: 'https://bmc1.local:443')),
        matcher: const _PathMatcher(),
      );
      adapter.onGet(
        '/redfish/v1/Systems',
        (server) => server.reply(200, <String, dynamic>{
          'Members': <Map<String, dynamic>>[
            <String, dynamic>{'@odata.id': '/redfish/v1/Systems/system'},
          ],
        }),
      );
      adapter.onGet(
        '/redfish/v1/Systems/system',
        (server) => server.reply(200, <String, dynamic>{
          '@odata.id': '/redfish/v1/Systems/system',
          'Manufacturer': 'OpenBMC',
          'Model': 'Rainier',
          'SerialNumber': 'SN1',
          'PowerState': 'On',
          'Status': <String, dynamic>{'Health': 'OK'},
          'ProcessorSummary': <String, dynamic>{
            'Count': 2,
            'Model': 'P9',
          },
          'MemorySummary': <String, dynamic>{
            'TotalSystemMemoryGiB': 64,
          },
          'IndicatorLED': 'Lit',
          'Links': <String, dynamic>{
            'Chassis': <Map<String, dynamic>>[
              <String, dynamic>{'@odata.id': '/redfish/v1/Chassis/chassis'},
            ],
          },
        }),
      );
      adapter.onGet(
        '/redfish/v1/Chassis/chassis/Thermal',
        (server) => server.reply(200, <String, dynamic>{
          'Temperatures': <Map<String, dynamic>>[
            <String, dynamic>{'Name': 'CPU', 'ReadingCelsius': 42.5},
          ],
        }),
      );

      final SystemOverview o = await fetchOverview(
        managerWithClient(clientWithAdapter(adapter)),
      );
      expect(o.manufacturer, 'OpenBMC');
      expect(o.model, 'Rainier');
      expect(o.serialNumber, 'SN1');
      expect(o.powerState, PowerState.on);
      expect(o.health, Health.ok);
      expect(o.processorSummary.count, 2);
      expect(o.memorySummary.totalGiB, 64);
      expect(o.indicatorLed, IndicatorLed.lit);
      expect(o.hasTemperature, isTrue);
      expect(o.leadingTemperatureCelsius, 42.5);
      expect(o.resourceUri, '/redfish/v1/Systems/system');
    });

    test('omits temperature when the system has no chassis link', () async {
      final DioAdapter adapter = DioAdapter(
        dio: Dio(BaseOptions(baseUrl: 'https://bmc1.local:443')),
        matcher: const _PathMatcher(),
      );
      adapter.onGet(
        '/redfish/v1/Systems',
        (server) => server.reply(200, <String, dynamic>{
          'Members': <Map<String, dynamic>>[
            <String, dynamic>{'@odata.id': '/redfish/v1/Systems/system'},
          ],
        }),
      );
      adapter.onGet(
        '/redfish/v1/Systems/system',
        (server) => server.reply(200, <String, dynamic>{
          'Manufacturer': 'Acme',
          'Status': <String, dynamic>{'Health': 'Warning'},
        }),
      );

      final SystemOverview o = await fetchOverview(
        managerWithClient(clientWithAdapter(adapter)),
      );
      expect(o.manufacturer, 'Acme');
      expect(o.health, Health.warning);
      expect(o.hasTemperature, isFalse);
      expect(o.leadingTemperatureCelsius, isNull);
    });

    test('throws a RedfishException when no ComputerSystems are reported',
        () async {
      final DioAdapter adapter = DioAdapter(
        dio: Dio(BaseOptions(baseUrl: 'https://bmc1.local:443')),
        matcher: const _PathMatcher(),
      );
      adapter.onGet(
        '/redfish/v1/Systems',
        (server) => server.reply(200, <String, dynamic>{
          'Members': <Map<String, dynamic>>[],
        }),
      );

      final SystemManager m = managerWithClient(clientWithAdapter(adapter));
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          systemManagerProvider.overrideWith((ref) => m),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(overviewProvider('bmc1').future),
        throwsA(
          isA<RedfishException>().having(
            (e) => e.errorCode,
            'errorCode',
            'Base.1.0.ResourceMissing',
          ),
        ),
      );
    });

    test('throws NotConnected when no client is available', () async {
      final SystemManager m = SystemManager(
        repository: InMemoryProfileRepository(),
        storage: InMemoryStorage(),
      );
      m.state = SystemState(
        systems: <String, SystemHandle>{
          'bmc1': SystemHandle(
            profile: const ConnectionProfile(id: 'bmc1', host: 'h'),
            status: ConnectionStatus.connected,
            session: Session(
              systemId: 'bmc1',
              token: 't',
              location: '',
              username: '',
            ),
            // No client.
            features: const SystemFeatures(systemId: 'bmc1'),
            snapshot: SystemSnapshot(resourceUri: '/redfish/v1/Systems/system'),
          ),
        },
        selectedId: 'bmc1',
      );

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          systemManagerProvider.overrideWith((ref) => m),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(overviewProvider('bmc1').future),
        throwsA(
          isA<RedfishException>().having(
            (e) => e.errorCode,
            'errorCode',
            'Base.1.0.NotConnected',
          ),
        ),
      );
    });
  });
}
