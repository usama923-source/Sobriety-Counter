import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the Money Saved calculator inputs and calculations.
///
/// Persists [drinksPerDay] and [costPerDrink] in SharedPreferences.
/// Provides computed values: moneySaved, drinksAvoided, monthlySavings, etc.
class SavingsService extends ChangeNotifier {
  static const _drinksPerDayKey = 'savings_drinks_per_day';
  static const _costPerDrinkKey = 'savings_cost_per_drink';

  int _drinksPerDay = 5;
  double _costPerDrink = 5.0;

  /// Total days sober (set externally by the home screen).
  int totalDays = 0;

  int get drinksPerDay => _drinksPerDay;
  double get costPerDrink => _costPerDrink;

  // ── Computed values ────────────────────────────────────────────────

  double get moneySaved => totalDays * _drinksPerDay * _costPerDrink;
  int get drinksAvoided => totalDays * _drinksPerDay;
  double get monthlySavings => 30 * _drinksPerDay * _costPerDrink;
  double get yearlySavings => 365 * _drinksPerDay * _costPerDrink;
  double get dailyCost => _drinksPerDay * _costPerDrink;

  // ── Setters (persist automatically) ────────────────────────────────

  Future<void> setDrinksPerDay(int value) async {
    if (value < 0) value = 0;
    if (value > 100) value = 100;
    _drinksPerDay = value;
    await _save();
    notifyListeners();
  }

  Future<void> setCostPerDrink(double value) async {
    if (value < 0) value = 0;
    if (value > 100) value = 100;
    _costPerDrink = double.parse(value.toStringAsFixed(2));
    await _save();
    notifyListeners();
  }

  // ── Initialization ─────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _drinksPerDay = prefs.getInt(_drinksPerDayKey) ?? 5;
    _costPerDrink = prefs.getDouble(_costPerDrinkKey) ?? 5.0;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_drinksPerDayKey, _drinksPerDay);
    await prefs.setDouble(_costPerDrinkKey, _costPerDrink);
  }
}
