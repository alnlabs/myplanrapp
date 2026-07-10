import 'dart:async';

import 'package:http/http.dart' as http;

/// Upper bound for a single Supabase/API HTTP round-trip.
const kApiRequestTimeout = Duration(seconds: 30);

/// Wraps the default HTTP client so stalled requests fail instead of hanging.
class TimeoutHttpClient extends http.BaseClient {
  TimeoutHttpClient({
    http.Client? inner,
    this.requestTimeout = kApiRequestTimeout,
  }) : _inner = inner ?? http.Client();

  final http.Client _inner;
  final Duration requestTimeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request).timeout(
      requestTimeout,
      onTimeout: () => throw TimeoutException(
        'Request timed out after ${requestTimeout.inSeconds}s',
      ),
    );
  }

  @override
  void close() => _inner.close();
}
