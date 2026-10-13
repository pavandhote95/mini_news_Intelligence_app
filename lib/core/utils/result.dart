import '../error/failures.dart';

/// Either a successful value or a [Failure].
///
/// Repositories return `Result` instead of throwing, which forces callers
/// to handle the error path explicitly.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    return switch (this) {
      Success<T>(:final data) => onSuccess(data),
      Err<T>(:final failure) => onFailure(failure),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
