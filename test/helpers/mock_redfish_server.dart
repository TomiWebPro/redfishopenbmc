import 'dart:convert';
import 'dart:io';

import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';

/// An in-process Redfish mock server that serves the real DMTF
/// `public-rackmount1` mockup from [fixturesDir] over genuine HTTP.
///
/// This is the project's stand-in "test platform": it lets the client,
/// discovery engine, and every feature service be exercised end-to-end against
/// authentic Redfish payload shapes without a live BMC. Mapping example:
///
///   GET  /redfish/v1/Chassis/1U/Thermal
///     -> &lt;fixturesDir&gt;/Chassis/1U/Thermal/index.json
///   POST /redfish/v1/.../Actions/...
///     -> 202 + Location: .../Tasks/1 (synthetic task)
///
/// Point a [RedfishClient] at [baseUrl] (see [buildClient]) and the rest of the
/// stack behaves exactly as it would against hardware.
class MockRedfishServer {
  /// Creates a server that will serve [fixturesDir] (the folder holding the
  /// mockup's root `index.json`, i.e. the `redfish/v1` document root).
  MockRedfishServer({required this.fixturesDir});

  /// Directory containing the unzipped DMTF mockup document root.
  final String fixturesDir;

  HttpServer? _server;

  /// The ephemeral localhost port the server bound to (valid after [start]).
  int get port => _server?.port ?? 0;

  /// Base URL to point a [RedfishClient] at, e.g.
  /// `http://127.0.0.1:54321/redfish/v1`.
  String get baseUrl => 'http://127.0.0.1:$port/redfish/v1';

  /// Starts listening on an ephemeral loopback port.
  Future<MockRedfishServer> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen(_handleRequest);
    return this;
  }

  void _handleRequest(HttpRequest request) {
    try {
      final String path = request.uri.path;
      if (request.method == 'POST' ||
          request.method == 'PUT' ||
          request.method == 'PATCH' ||
          request.method == 'DELETE') {
        // Action endpoints (Reset, SimpleUpdate, …) are accepted and handed a
        // synthetic task monitor so callers exercising the async flow work.
        _respond(request, 202, headers: <String, String>{
          'Location': '$path/Tasks/1',
        });
        return;
      }

      final String? filePath = _resolve(path);
      if (filePath == null || !File(filePath).existsSync()) {
        _respond(request, 404, body: _error('Base.1.0.ResourceNotFound', path));
        return;
      }
      final String contents = File(filePath).readAsStringSync();
      _respond(request, 200, body: contents);
    } catch (e) {
      _respond(request, 500, body: _error('Base.1.0.InternalError', e.toString()));
    }
  }

  /// Maps a request path under `/redfish/v1` to a mockup file.
  String? _resolve(String rawPath) {
    String path = rawPath;
    if (path.startsWith('/redfish/v1')) {
      path = path.substring('/redfish/v1'.length);
    }
    if (path.isEmpty || path == '/') {
      return _join(fixturesDir, 'index.json');
    }
    if (path.endsWith('/')) path = path.substring(0, path.length - 1);
    if (path.startsWith('/')) path = path.substring(1);

    final String asResource = _join(fixturesDir, path, 'index.json');
    if (File(asResource).existsSync()) return asResource;
    final String asFile = _join(fixturesDir, path);
    if (File(asFile).existsSync()) return asFile;
    final String asJson = _join(fixturesDir, '$path.json');
    if (File(asJson).existsSync()) return asJson;
    return null;
  }

  String _join(String base, String part, [String? tail]) {
    final StringBuffer b = StringBuffer(base);
    if (!base.endsWith('/')) b.write('/');
    b.write(part);
    if (tail != null) {
      if (!part.endsWith('/')) b.write('/');
      b.write(tail);
    }
    return b.toString();
  }

  void _respond(
    HttpRequest request,
    int status, {
    String body = '{}',
    Map<String, String>? headers,
  }) {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..headers.set('OData-Version', '4.0');
    headers?.forEach((String k, String v) => request.response.headers.set(k, v));
    request.response.write(body);
    request.response.close();
  }

  String _error(String code, String message) => jsonEncode(<String, dynamic>{
        'error': <String, dynamic>{
          'code': code,
          'message': message,
        }
      });

  /// Builds a [RedfishClient] pointed at this server (plain http, no TLS).
  RedfishClient buildClient({String systemId = 'bmc1'}) {
    final ConnectionProfile profile = ConnectionProfile(
      id: systemId,
      host: '127.0.0.1',
      port: port,
      scheme: 'http',
      allowSelfSigned: true,
    );
    return RedfishClient(profile: profile);
  }

  /// Stops the server.
  Future<void> close() async {
    await _server?.close(force: true);
    _server = null;
  }
}
