import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_theme_mode_getters.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferThemeModeGettersTest);
    defineReflectiveTests(PreferThemeModeGettersWithoutGettersTest);
  });
}

@reflectiveTest
class PreferThemeModeGettersTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferThemeModeGetters();
    newPackage('flutter').addFile('lib/material.dart', r'''
enum ThemeMode {
  system,
  light,
  dark;

  bool get isSystem => this == ThemeMode.system;
  bool get isLight => this == ThemeMode.light;
  bool get isDark => this == ThemeMode.dark;
}
''');
    super.setUp();
  }

  // --- Positive cases (should trigger lint) ---

  Future<void> test_equalsDark() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/material.dart';

bool isDarkMode(ThemeMode mode) => mode == ThemeMode.dark;
''',
      [lint(76, 22)],
    );
  }

  Future<void> test_notEqualsLight() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/material.dart';

bool notLight(ThemeMode mode) => mode != ThemeMode.light;
''',
      [lint(74, 23)],
    );
  }

  Future<void> test_constantOnLeft() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/material.dart';

bool isSystem(ThemeMode mode) => ThemeMode.system == mode;
''',
      [lint(74, 24)],
    );
  }

  // --- Negative cases (should NOT trigger lint) ---

  Future<void> test_getterAlreadyUsed() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

bool isDarkMode(ThemeMode mode) => mode.isDark;
''');
  }

  Future<void> test_comparisonBetweenTwoVariables() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

bool same(ThemeMode a, ThemeMode b) => a == b;
''');
  }

  Future<void> test_unrelatedEnumWithSameConstant() async {
    await assertNoDiagnostics(r'''
enum ThemeMode { dark, light }

bool isDark(ThemeMode mode) => mode == ThemeMode.dark;
''');
  }

  Future<void> test_switchOnThemeMode() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

bool isDarkMode(ThemeMode mode) => switch (mode) {
  ThemeMode.dark => true,
  _ => false,
};
''');
  }
}

/// Older Flutter versions have no `isDark`/`isLight`/`isSystem` getters, so
/// the rule must stay silent there.
@reflectiveTest
class PreferThemeModeGettersWithoutGettersTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferThemeModeGetters();
    newPackage('flutter').addFile('lib/material.dart', r'''
enum ThemeMode { system, light, dark }
''');
    super.setUp();
  }

  Future<void> test_noGettersOnEnum() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

bool isDarkMode(ThemeMode mode) => mode == ThemeMode.dark;
''');
  }
}
