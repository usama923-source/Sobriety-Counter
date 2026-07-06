import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quit_drinking/core/utils/result.dart';

/// Centralized error handling utilities for the application.
class ErrorHandler {
  ErrorHandler._();

  /// Safely execute a [callback] that returns a [Result]. Returns the result
  /// or a [Failure] if an exception is thrown.
  static Future<Result<T>> safeCall<T>(Future<T> Function() callback) async {
    try {
      final result = await callback();
      return Success(result);
    } catch (e) {
      debugPrint('[ErrorHandler] Exception: $e');
      return Failure(
        e is Exception ? e.toString() : 'An unexpected error occurred.',
        exception: e,
      );
    }
  }

  /// Log an error to the console (in debug mode).
  static void logError(String message, [Object? error, StackTrace? stack]) {
    debugPrint('[Error] $message${error != null ? ' — $error' : ''}');
    if (stack != null && kDebugMode) {
      debugPrint('Stack trace: $stack');
    }
  }

  /// Show a SnackBar with an error message.
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, size: 20, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
