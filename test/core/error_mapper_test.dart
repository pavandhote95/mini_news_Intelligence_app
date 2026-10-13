import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_news_intelligence/core/error/error_mapper.dart';
import 'package:mini_news_intelligence/core/error/exceptions.dart';
import 'package:mini_news_intelligence/core/error/failures.dart';
import 'package:mini_news_intelligence/core/utils/date_formatter.dart';
import 'package:mini_news_intelligence/core/utils/validators.dart';

void main() {
  group('ErrorMapper', () {
    final options = RequestOptions(path: '/top-headlines');

    test('connection errors become NetworkFailure', () {
      final e = DioException(requestOptions: options, type: DioExceptionType.connectionError);
      expect(ErrorMapper.map(e), isA<NetworkFailure>());
    });

    test('timeouts become TimeoutFailure', () {
      final e = DioException(requestOptions: options, type: DioExceptionType.receiveTimeout);
      expect(ErrorMapper.map(e), isA<TimeoutFailure>());
    });

    test('NewsAPI error codes are mapped', () {
      Failure badResponse(int status, String code) => ErrorMapper.map(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response<dynamic>(
                requestOptions: options,
                statusCode: status,
                data: {'status': 'error', 'code': code, 'message': 'msg'},
              ),
            ),
          );

      expect(badResponse(401, 'apiKeyInvalid'), isA<ApiKeyFailure>());
      expect(badResponse(429, 'rateLimited'), isA<RateLimitFailure>());
      expect(badResponse(426, 'maximumResultsReached'), isA<EndOfResultsFailure>());
      expect(badResponse(500, 'unexpectedError'), isA<ServerFailure>());
    });

    test('missing api key is reported clearly', () {
      expect(ErrorMapper.map(const MissingApiKeyException()), isA<ApiKeyFailure>());
    });
  });

  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('nope'), isNotNull);
      expect(Validators.email('jane@acme.com'), isNull);
    });

    test('password', () {
      expect(Validators.password('123'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });
  });

  group('DateFormatter.relative', () {
    final now = DateTime(2026, 10, 13, 12);

    test('formats recent times', () {
      expect(DateFormatter.relative(now.subtract(const Duration(seconds: 20)), now: now), 'Just now');
      expect(DateFormatter.relative(now.subtract(const Duration(minutes: 5)), now: now), '5m ago');
      expect(DateFormatter.relative(now.subtract(const Duration(hours: 3)), now: now), '3h ago');
      expect(DateFormatter.relative(now.subtract(const Duration(days: 2)), now: now), '2d ago');
    });

    test('falls back to a full date after a week', () {
      expect(DateFormatter.relative(DateTime(2026, 9, 1), now: now), '1 Sep 2026');
    });
  });
}
