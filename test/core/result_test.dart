import 'package:flutter_test/flutter_test.dart';
import 'package:quit_drinking/core/utils/result.dart';

void main() {
  group('Result type', () {
    test('Success holds data correctly', () {
      const result = Success<String>('hello');
      expect(result.data, 'hello');
      expect(result, isA<Result<String>>());
    });

    test('Failure holds error message correctly', () {
      const result = Failure<String>('Something went wrong');
      expect(result.error, 'Something went wrong');
      expect(result.exception, isNull);
      expect(result, isA<Result<String>>());
    });

    test('Failure can hold exception', () {
      final exception = Exception('test error');
      final result = Failure<String>('Failed', exception: exception);
      expect(result.error, 'Failed');
      expect(result.exception, exception);
    });

    group('orThrow', () {
      test('returns data on success', () {
        const result = Success<String>('data');
        expect(result.orThrow, 'data');
      });

      test('throws on failure', () {
        const result = Failure<String>('error');
        expect(() => result.orThrow, throwsException);
      });
    });

    group('orDefault', () {
      test('returns data on success', () {
        const result = Success<String>('data');
        expect(result.orDefault('default'), 'data');
      });

      test('returns default on failure', () {
        const result = Failure<String>('error');
        expect(result.orDefault('default'), 'default');
      });
    });

    group('orNull', () {
      test('returns data on success', () {
        const result = Success<String>('data');
        expect(result.orNull, 'data');
      });

      test('returns null on failure', () {
        const result = Failure<String>('error');
        expect(result.orNull, isNull);
      });
    });

    group('fold', () {
      test('calls onSuccess for Success', () {
        const result = Success<String>('hello');
        final output = result.fold(
          (data) => 'Got: $data',
          (error) => 'Error: $error',
        );
        expect(output, 'Got: hello');
      });

      test('calls onFailure for Failure', () {
        const result = Failure<String>('broken');
        final output = result.fold(
          (data) => 'Got: $data',
          (error) => 'Error: $error',
        );
        expect(output, 'Error: broken');
      });
    });

    test('Fold correctly maps Success and Failure', () {
      const success = Success<int>(42);
      expect(success.fold((d) => d, (e) => -1), 42);

      const failure = Failure<int>('error');
      expect(failure.fold((d) => d, (e) => -1), -1);
    });
  });
}
