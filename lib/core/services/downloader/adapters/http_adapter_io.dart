import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void configureHttpClientAdapter(Dio dio) {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      // Bypass SSL handshake errors caused by deep packet inspection or proxy certificates in Iran
      client.badCertificateCallback = (cert, host, port) => true;
      
      // Bypass local proxy (e.g. 127.0.0.1:2080) for localhost, 127.0.0.1, or local subnet IPs
      client.findProxy = (uri) {
        final host = uri.host.toLowerCase();
        if (host == 'localhost' ||
            host == '127.0.0.1' ||
            host.startsWith('172.') ||
            host.startsWith('192.168.') ||
            host.startsWith('10.')) {
          return 'DIRECT';
        }
        return HttpClient.findProxyFromEnvironment(uri);
      };

      // Short idleTimeout ensures stale sockets are purged before reusing dead keep-alive sockets
      client.idleTimeout = const Duration(seconds: 5);
      client.connectionTimeout = const Duration(seconds: 15);
      return client;
    },
  );
}
