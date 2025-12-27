import 'package:flutter/material.dart';

/// Represents a navigation tab in the application
class TabInfo {
  const TabInfo({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge,
  });

  /// Icon to show when tab is inactive
  final IconData icon;

  /// Icon to show when tab is active
  final IconData activeIcon;

  /// Label for the tab
  final String label;

  /// Optional badge count to show on the tab
  final int? badge;

  /// Create a copy with optional new values
  TabInfo copyWith({
    IconData? icon,
    IconData? activeIcon,
    String? label,
    int? badge,
  }) {
    return TabInfo(
      icon: icon ?? this.icon,
      activeIcon: activeIcon ?? this.activeIcon,
      label: label ?? this.label,
      badge: badge ?? this.badge,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TabInfo &&
        other.icon == icon &&
        other.activeIcon == activeIcon &&
        other.label == label &&
        other.badge == badge;
  }

  @override
  int get hashCode =>
      icon.hashCode ^ activeIcon.hashCode ^ label.hashCode ^ badge.hashCode;
}
