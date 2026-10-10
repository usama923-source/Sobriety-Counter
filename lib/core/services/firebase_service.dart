import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Thin wrapper around Firebase Analytics for this app.
///
/// Responsibilities:
/// - Generates and persists a UUID device ID on first launch
///   (SharedPreferences key: "device_id")
/// - Logs the "app_open" and "pro_purchase" analytics events
///
/// All methods are safe to call before/without Firebase initialization —
/// failures are caught and logged so the app never crashes on Firebase issues.
class FirebaseService {
  // Singleton instance (matches NotificationService pattern)
  static final FirebaseService _instance = FirebaseService._();
  factory FirebaseService() => _instance;
  FirebaseService._();

  static const String _deviceIdKey = 'device_id';

  final Uuid _uuid = const Uuid();
  String? _deviceId;

  /// The cached device ID, or empty string if not yet generated.
  String get deviceId => _deviceId ?? '';

  /// Generate a UUID device ID on first launch and persist it.
  ///
  /// Subsequent calls return the already-stored ID so the user keeps a
  /// stable identity across app restarts.
  Future<String> getOrCreateDeviceId() async {
    if (_deviceId != null && _deviceId!.isNotEmpty) return _deviceId!;

    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString(_deviceIdKey);
    final newId = _uuid.v4();

    if (storedId == null || storedId.isEmpty) {
      await prefs.setString(_deviceIdKey, newId);
    }

    _deviceId = storedId ?? newId;
    return storedId ?? newId;
  }

  /// Log the "app_open" Firebase Analytics event.
  Future<void> logAppOpen() async {
    try {
      await getOrCreateDeviceId();
      await FirebaseAnalytics.instance.logEvent(name: 'app_open');
    } catch (e) {
      debugPrint('[FirebaseService] logAppOpen failed (non-fatal): $e');
    }
  }

  /// Log the "pro_purchase" Firebase Analytics event.
  ///
  /// The Firestore write to "pro_purchases" was removed because
  /// firestore.rules denies client writes. Real billing will record the
  /// purchase server-side later.
  Future<void> logProPurchase() async {
    try {
      await getOrCreateDeviceId();
      await FirebaseAnalytics.instance.logEvent(name: 'pro_purchase');
    } catch (e) {
      debugPrint('[FirebaseService] logProPurchase failed (non-fatal): $e');
    }
  }
}
