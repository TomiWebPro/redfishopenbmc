import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

HttpClientAdapter createHttpClientAdapter(bool allowSelfSigned) {
  if (!allowSelfSigned) {
    // Default: validates certificates (TLS-first).
    return IOHttpClientAdapter();
  }
  // Opt-in self-signed: accept any cert. This is a deliberate security
  // downgrade and must be acknowledged per-profile by the caller (#010).
  return IOHttpClientAdapter(
    createHttpClient: () {
      final HttpClient client = HttpClient()
        ..badCertificateCallback =
            (X509Certificate _, String __, int ___) => true;
      return client;
    },
  );
}
