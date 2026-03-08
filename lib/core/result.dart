/// Represents the result of a repository or service operation.
sealed class Result<T> {
  /// Creates a result value.
  const Result();

  /// Returns `true` when this result contains data.
  bool get isSuccess => this is Success<T>;

  /// Returns `true` when this result contains an error.
  bool get isFailure => this is Failure<T>;

  /// Returns the contained data when successful, otherwise `null`.
  T? get dataOrNull => switch (this) {
        Success<T>(data: final data) => data,
        Failure<T>() => null,
      };

  /// Returns the failure message when unsuccessful, otherwise `null`.
  String? get messageOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(message: final message) => message,
      };

  /// Maps the result into a new value.
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, Object? error) failure,
  }) {
    return switch (this) {
      Success<T>(data: final data) => success(data),
      Failure<T>(message: final message, error: final error) =>
        failure(message, error),
    };
  }
}

/// Represents a successful operation with typed data.
final class Success<T> extends Result<T> {
  /// Creates a successful result.
  const Success(this.data);

  /// The successful value.
  final T data;
}

/// Represents a failed operation with a user-safe message.
final class Failure<T> extends Result<T> {
  /// Creates a failed result.
  const Failure(this.message, {this.error});

  /// The user-safe failure message.
  final String message;

  /// The underlying error when available.
  final Object? error;
}
