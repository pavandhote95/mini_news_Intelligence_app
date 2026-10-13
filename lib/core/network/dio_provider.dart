import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import 'api_endpoints.dart';

/// Single, app-wide configured HTTP client.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
      // The key travels in a header rather than the URL so it never shows up in logs.
      headers: {'X-Api-Key': Env.newsApiKey},
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        responseHeader: false,
        logPrint: (o) => debugPrint(o.toString()),
      ),
    );
  }

  ref.onDispose(dio.close);
  return dio;
});
