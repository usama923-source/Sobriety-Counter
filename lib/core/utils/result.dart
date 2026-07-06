/// A sealed result type that represents either a success value or a failure
/// with an error. Used throughout the repository layer for explicit error handling.
///
/// Usage:
/// ```dart
/// Future<Result<List<String>>> loadReasons() async { ... }
/// ```
sealed class Result<T> {
  const Result();
}

/// Represents a successful operation with a value of type [T].
final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Represents a failed operation with an [error] message and optional [exception].
final class Failure<T> extends Result<T> {
  final String error;
  final Object? exception;

  const Failure(this.error, {this.exception});

  @override
  String toString() => 'Failure: $error${exception != null ? ' ($exception)' : ''}';
}

/// Extension methods for convenient Result handling.
extension ResultExtension<T> on Result<T> {
  /// Unwraps the value or throws if it's a failure.
  T get orThrow => switch (this) {
        Success(data: final d) => d,
        Failure(error: final e) => throw Exception(e),
      };

  /// Returns the value if success, or [defaultValue] if failure.
  T orDefault(T defaultValue) => switch (this) {
        Success(data: final d) => d,
        Failure _ => defaultValue,
      };

  /// Returns the value if success, or null if failure.
  T? get orNull => switch (this) {
        Success(data: final d) => d,
        Failure _ => null,
      };

  /// Calls [onSuccess] if this is a Success, or [onFailure] if this is a Failure.
  R fold<R>(R Function(T data) onSuccess, R Function(String error) onFailure) =>
      switch (this) {
        Success(data: final d) => onSuccess(d),
        Failure(error: final e) => onFailure(e),
      };
}
