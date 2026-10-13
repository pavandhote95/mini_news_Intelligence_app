/// A user-presentable description of something that went wrong.
///
/// `sealed` lets the UI switch exhaustively over every failure type
/// (e.g. to pick an icon), and the compiler warns if a new one is added
/// without being handled.
sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'You appear to be offline. Check your connection and try again.',
  ]);
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure([
    super.message = 'The news service is taking too long to respond. Please try again.',
  ]);
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});

  final int? statusCode;
}

final class ApiKeyFailure extends Failure {
  const ApiKeyFailure([
    super.message =
        'News API key is missing or invalid. Run the app with --dart-define-from-file=env.json.',
  ]);
}

final class RateLimitFailure extends Failure {
  const RateLimitFailure([
    super.message = 'Daily request limit reached for the news API. Try again later.',
  ]);
}

/// The API has no more results for this query (NewsAPI caps free plans at 100).
final class EndOfResultsFailure extends Failure {
  const EndOfResultsFailure([super.message = "You've reached the end of the results."]);
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Could not access local storage.']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong. Please try again.']);
}
