import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tri-state app theme. Defaults to [ThemeMode.system] so first-run users
/// inherit their device preference; flipping the dashboard toggle pins it
/// for the rest of the session. (Persistence across launches will land in
/// a later phase alongside a proper Settings screen.)
final StateProvider<ThemeMode> themeModeProvider = StateProvider<ThemeMode>(
  (StateProviderRef<ThemeMode> ref) => ThemeMode.system,
);

extension ThemeModeCycle on ThemeMode {
  /// Cycles `system → light → dark → system` for the dashboard quick toggle.
  ThemeMode get next {
    switch (this) {
      case ThemeMode.system:
        return ThemeMode.light;
      case ThemeMode.light:
        return ThemeMode.dark;
      case ThemeMode.dark:
        return ThemeMode.system;
    }
  }

  IconData get icon {
    switch (this) {
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
    }
  }

  String get label {
    switch (this) {
      case ThemeMode.system:
        return 'System theme';
      case ThemeMode.light:
        return 'Light theme';
      case ThemeMode.dark:
        return 'Dark theme';
    }
  }
}
