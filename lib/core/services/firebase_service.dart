import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Thin wrapper around Firebase (Analytics + Firestore) for this app.
///
/// Responsibilities:
/// - Generates and persists a UUID device ID on first launch
///   (SharedPreferences key: "device_id")
/// - Logs the "app_open" analytics event
/// - Records Pro purchases into the Firestore "pro_purchases" collection
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
    var id = prefs.getString(_deviceIdKey);
    if (id == null || id.isEmpty) {
      id = _uuid.v4();
      await prefs.setString(_deviceIdKey, id);
    }
    _deviceId = id;
    return id;
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

  /// Record a Pro purchase in Firestore and log an analytics event.
  ///
  /// Writes a document to the "pro_purchases" collection:
  /// { deviceId, purchaseDate, amount: 2.99, currency: 'USD' }
  Future<void> logProPurchase() async {
    try {
      final id = await getOrCreateDeviceId();
      await FirebaseFirestore.instance.collection('pro_purchases').add({
        'deviceId': id,
        'purchaseDate': FieldValue.serverTimestamp(),
        'amount': 2.99,
        'currency': 'USD',
      });
      await FirebaseAnalytics.instance.logEvent(name: 'pro_purchase');
    } catch (e) {
      debugPrint('[FirebaseService] logProPurchase failed (non-fatal): $e');
    }
  }
}
