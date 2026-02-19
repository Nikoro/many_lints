import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_sized_box_square.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferSizedBoxSquareTest));
}

@reflectiveTest
class PreferSizedBoxSquareTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferSizedBoxSquare();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {}
class Key {}
class SizedBox extends Widget {
  const SizedBox({Key? key, double? width, double? height, Widget? child});
  const SizedBox.square({Key? key, double? dimension, Widget? child});
  const SizedBox.shrink({Key? key, Widget? child});
  const SizedBox.expand({Key? key, Widget? child});
}
class Text extends Widget {
  const Text(String data);
}
''');
    super.setUp();
  }

  // === Tests that SHOULD trigger the lint ===

  Future<void> test_sameIntegerLiterals() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox(height: 10, width: 10);
}
''',
      [lint(61, 8)],
    );
  }

  Future<void> test_sameDoubleLiterals() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox(height: 24.0, width: 24.0);
}
''',
      [lint(61, 8)],
    );
  }

  Future<void> test_sameVariableReference() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  const size = 48.0;
  return SizedBox(height: size, width: size);
}
''',
      [lint(82, 8)],
    );
  }

  Future<void> test_withChildAndKey() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox(
    width: 50,
    height: 50,
    child: Text('Hi'),
  );
}
''',
      [lint(61, 8)],
    );
  }

  Future<void> test_constSizedBox() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return const SizedBox(width: 10, height: 10);
}
''',
      [lint(67, 8)],
    );
  }

  // === Tests that should NOT trigger the lint ===

  Future<void> test_differentValues() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox(height: 10, width: 20);
}
''');
  }

  Future<void> test_onlyWidth() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox(width: 10);
}
''');
  }

  Future<void> test_onlyHeight() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox(height: 10);
}
''');
  }

  Future<void> test_alreadySquare() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox.square(dimension: 10);
}
''');
  }

  Future<void> test_shrinkConstructor() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox.shrink();
}
''');
  }

  Future<void> test_noDimensions() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox(child: Text('Hi'));
}
''');
  }

  // === Edge cases ===

  Future<void> test_differentVariablesSameValue() async {
    // Different variable names — should NOT trigger even if runtime values
    // might be the same, because source text differs.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  const a = 10.0;
  const b = 10.0;
  return SizedBox(height: a, width: b);
}
''');
  }
}
