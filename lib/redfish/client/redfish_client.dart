// Placeholder Dio client for #002 — not wired in #001.
// Keeps dir structure valid for analysis.

import 'package:dio/dio.dart';

class RedfishClient {
  RedfishClient({required String host, int port = 443, Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://$host:$port',
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 30),
                headers: <String, String>{
                  'Accept': 'application/json',
                  'OData-Version': '4.0',
                },
              ),
            );

  final Dio _dio;

  Dio get dio => _dio;
}
