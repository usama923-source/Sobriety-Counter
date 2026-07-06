import 'package:flutter/material.dart';

/// Represents a single sobriety milestone.
class Milestone {
  final int dayThreshold;
  final String label;
  final IconData icon;
  final IconData completedIcon;

  const Milestone({
    required this.dayThreshold,
    required this.label,
    required this.icon,
    this.completedIcon = Icons.check_circle_rounded,
  });

  bool isCompleted(int currentDays) => currentDays >= dayThreshold;

  double progressTowards(int currentDays) {
    return (currentDays / dayThreshold).clamp(0.0, 1.0);
  }

  static const List<Milestone> all = [
    Milestone(dayThreshold: 1, label: '1 Day', icon: Icons.looks_one_rounded),
    Milestone(dayThreshold: 3, label: '3 Days', icon: Icons.looks_two_rounded),
    Milestone(dayThreshold: 7, label: '1 Week', icon: Icons.star_rounded),
    Milestone(dayThreshold: 14, label: '2 Weeks', icon: Icons.auto_awesome_rounded),
    Milestone(dayThreshold: 30, label: '1 Month', icon: Icons.calendar_month_rounded),
    Milestone(dayThreshold: 90, label: '3 Months', icon: Icons.spa_rounded),
    Milestone(dayThreshold: 180, label: '6 Months', icon: Icons.auto_awesome_rounded),
    Milestone(dayThreshold: 365, label: '1 Year', icon: Icons.emoji_events_rounded),
  ];
}
