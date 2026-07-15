// ignore_for_file: unused_local_variable

// prefer_theme_mode_getters
//
// Warns when a ThemeMode value is compared with == or != against a ThemeMode
// constant instead of using the isDark/isLight/isSystem getters
// (Flutter 3.44+).

import 'package:flutter/material.dart';

// ❌ Bad: comparisons against ThemeMode constants
class BadExamples {
  void example(ThemeMode mode) {
    // LINT: use mode.isDark
    final isDark = mode == ThemeMode.dark;

    // LINT: use !mode.isLight
    final notLight = mode != ThemeMode.light;

    // LINT: constant on the left works too — use mode.isSystem
    final isSystem = ThemeMode.system == mode;
  }
}

// ✅ Good: dedicated getters
class GoodExamples {
  void example(ThemeMode mode) {
    final isDark = mode.isDark;
    final notLight = !mode.isLight;
    final isSystem = mode.isSystem;
  }
}

// ✅ Good: comparing two variables has no getter equivalent
class EdgeCases {
  bool same(ThemeMode a, ThemeMode b) => a == b;

  // ✅ Good: exhaustive switch is a different (valid) style
  bool isDarkMode(ThemeMode mode) => switch (mode) {
    ThemeMode.dark => true,
    _ => false,
  };
}
