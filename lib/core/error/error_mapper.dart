import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'exceptions.dart';
import 'failures.dart';

/// Converts any error thrown in the data layer into a [Failure].
abstract final class ErrorMapper {
  static Failure map(Object error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('ErrorMapper: $error');
    }

    return switch (error) {
      MissingApiKeyException() => const ApiKeyFailure(),
      ServerException(:final statusCode, :final code, :final message) =>
        fromServer(statusCode: statusCode, code: code, message: message),
      DioException() => _fromDio(error),
      CacheException(:final message) => CacheFailure(message),
      FormatException() || TypeError() =>
        const ServerFailure('Received an unexpected response from the news service.'),
      _ => const UnknownFailure(),
    };
  }

  static Failure _fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutFailure();
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badCertificate:
        return const NetworkFailure('A secure connection could not be established.');
      case DioExceptionType.cancel:
        return const UnknownFailure('The request was cancelled.');
      case DioExceptionType.badResponse:
        final response = e.response;
        final data = response?.data;
        String? code;
        String? message;
        if (data is Map) {
          code = data['code'] as String?;
          message = data['message'] as String?;
        }
        return fromServer(statusCode: response?.statusCode, code: code, message: message);
      case DioExceptionType.unknown:
        if (e.error is SocketException) return const NetworkFailure();
        return const UnknownFailure();
      case DioExceptionType.transformTimeout:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  /// Maps NewsAPI error codes (https://newsapi.org/docs/errors) to failures.
  static Failure fromServer({int? statusCode, String? code, String? message}) {
    switch (code) {
      case 'apiKeyMissing':
      case 'apiKeyInvalid':
      case 'apiKeyDisabled':
      case 'apiKeyExhausted':
        return const ApiKeyFailure();
      case 'rateLimited':
        return const RateLimitFailure();
      case 'maximumResultsReached':
        return const EndOfResultsFailure();
    }
    if (statusCode == 401) return const ApiKeyFailure();
    if (statusCode == 429) return const RateLimitFailure();
    if (statusCode != null && statusCode >= 500) {
      return ServerFailure(
        'The news service is temporarily unavailable. Please try again shortly.',
        statusCode: statusCode,
      );
    }
    return ServerFailure(
      message ?? 'Request failed${statusCode != null ? ' ($statusCode)' : ''}.',
      statusCode: statusCode,
    );
  }
}
