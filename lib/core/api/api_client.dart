import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_endpoints.dart';
import 'api_exception.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// The one way this app talks to the server.
///
/// Deliberately cookie-free. The API group has Sanctum's
/// `EnsureFrontendRequestsAreStateful` in front of it, which decides whether a
/// request is "stateful" from its `Referer`/`Origin` — and a stateful request
/// gets session middleware and CSRF checking, so every POST would come back
/// 419 with a message that mentions nothing about Sanctum. A native client
/// sends neither header and no cookies, which is what keeps every write
/// endpoint working. Do not add a cookie jar.
class ApiClient {
  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: Api.base,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Every server-side rate limiter keys on IP, and mobile users behind
        // carrier-grade NAT share one by the thousand — six enquiries an hour
        // would be six for a whole city. This gives the server a second
        // dimension to key on. It is not a security control (a client can
        // rotate it); it stops one network starving another.
        options.headers['X-Client-Id'] = await _clientId();
        handler.next(options);
      },
    ));
  }

  late final Dio _dio;
  String? _cachedClientId;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get<dynamic>(path, queryParameters: query);

      return _asMap(response.data);
    } on DioException catch (e) {
      throw _transform(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _dio.post<dynamic>(path, data: body);

      return _asMap(response.data);
    } on DioException catch (e) {
      throw _transform(e);
    }
  }

  /// A list endpoint returns `{data: [...]}`; a detail one `{data: {...}}`.
  /// Both are wrapped, so callers always get a map and reach in for `data`.
  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is List) return {'data': data};

    return const {};
  }

  /// Turns a transport failure into something worth showing a reader.
  ///
  /// The messages avoid blaming the reader for a server's silence, and avoid
  /// the word "error", which tells nobody anything.
  ApiException _transform(DioException e) {
    final response = e.response;

    if (response == null) {
      final timedOut = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;

      return ApiException(
        timedOut
            ? 'The server is taking too long to answer. Try again in a moment.'
            : 'Could not reach Take Care International. Check your connection.',
      );
    }

    final data = response.data;
    var message = 'Something went wrong. Please try again.';
    Map<String, List<String>>? errors;

    if (data is Map) {
      message = (data['message'] ?? data['error'] ?? message).toString();

      final raw = data['errors'];
      if (raw is Map) {
        errors = raw.map(
          (key, value) => MapEntry(
            key.toString(),
            (value is List ? value : [value]).map((v) => v.toString()).toList(),
          ),
        );
      }
    }

    if (response.statusCode == 429) {
      message = 'That is a lot of requests in a short time. Please wait a minute and try again.';
    }

    return ApiException(message, statusCode: response.statusCode, errors: errors);
  }

  /// A stable per-install identifier, generated once and kept.
  Future<String> _clientId() async {
    if (_cachedClientId != null) return _cachedClientId!;

    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('client_id');

    if (id == null) {
      final random = Random.secure();
      id = List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await prefs.setString('client_id', id);
    }

    return _cachedClientId = id;
  }
}
