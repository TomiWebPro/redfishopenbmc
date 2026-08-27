import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

HttpClientAdapter createHttpClientAdapter(bool allowSelfSigned) {
  // On the web, TLS is governed by the browser; certificates cannot be
  // suppressed programmatically. [allowSelfSigned] is therefore a no-op
  // here and self-signed BMCs must present a browser-trusted cert. The
  // flag is still accepted to keep the platform API uniform.
  return BrowserHttpClientAdapter();
}
