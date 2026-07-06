import 'package:flutter/material.dart';

/// Breakpoints for responsive layout.
class Breakpoints {
  static const double compact = 600; // phone
  static const double medium = 840; // tablet portrait
  static const double expanded = 1200; // desktop
}

/// Helper to determine the current screen size category.
enum ScreenSize {
  compact, // < 600
  medium, // 600 – 839
  expanded, // 840 – 1199
  large, // >= 1200
}

/// Provides responsive sizing based on screen width.
class ResponsiveHelper {
  final BuildContext context;

  ResponsiveHelper(this.context);

  /// Current screen width.
  double get width => MediaQuery.sizeOf(context).width;

  /// Current screen height.
  double get height => MediaQuery.sizeOf(context).height;

  /// Whether the device is in compact (phone) mode.
  bool get isCompact => width < Breakpoints.compact;

  /// Whether the device is in medium (tablet portrait) mode.
  bool get isMedium =>
      width >= Breakpoints.compact && width < Breakpoints.medium;

  /// Whether the device is in expanded (tablet landscape / small desktop) mode.
  bool get isExpanded =>
      width >= Breakpoints.medium && width < Breakpoints.expanded;

  /// Whether the device is in large (desktop) mode.
  bool get isLarge => width >= Breakpoints.expanded;

  /// Screen size category.
  ScreenSize get screenSize {
    if (isLarge) return ScreenSize.large;
    if (isExpanded) return ScreenSize.expanded;
    if (isMedium) return ScreenSize.medium;
    return ScreenSize.compact;
  }

  /// Returns the value for compact, medium, and expanded/large breakpoints.
  T responsive<T>({required T compact, T? medium, T? expanded, T? large}) {
    if (isLarge && large != null) return large;
    if (isExpanded && expanded != null) return expanded;
    if (isMedium && medium != null) return medium;
    return compact;
  }

  /// Horizontal padding that scales with screen size.
  double get horizontalPadding => responsive<double>(
        compact: 16,
        medium: 32,
        expanded: 48,
        large: 64,
      );

  /// Whether to show a navigation rail instead of a bottom nav bar.
  bool get showNavigationRail => !isCompact;

  /// Maximum content width constraint.
  double get maxContentWidth {
    if (isLarge) return 1200;
    if (isExpanded) return 900;
    return double.infinity;
  }

  /// Grid column count for responsive layouts.
  int get gridColumns => responsive<int>(
        compact: 1,
        medium: 2,
        expanded: 3,
        large: 4,
      );

  /// Spacing that scales with screen size.
  double get gridSpacing => responsive<double>(
        compact: 16,
        medium: 20,
        expanded: 24,
        large: 24,
      );
}

/// Extension on [BuildContext] for convenient access to responsive helpers.
extension ResponsiveContext on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);
}
