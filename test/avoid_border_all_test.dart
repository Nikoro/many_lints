import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_border_all.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidBorderAllTest));
}

@reflectiveTest
class AvoidBorderAllTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidBorderAll();
    newPackage('flutter').addFile('lib/painting.dart', r'''
class Color {
  const Color(int value);
}

enum BorderStyle { none, solid }

class BorderSide {
  const BorderSide({
    Color color = const Color(0xFF000000),
    double width = 1.0,
    BorderStyle style = BorderStyle.solid,
  });
}

class Border {
  const Border({BorderSide side = const BorderSide()});
  const Border.fromBorderSide(BorderSide side);
  factory Border.all({
    Color color = const Color(0xFF000000),
    double width = 1.0,
    BorderStyle style = BorderStyle.solid,
  }) => Border.fromBorderSide(BorderSide(color: color, width: width, style: style));
}

class BorderFactory {
  static Border all({
    Color color = const Color(0xFF000000),
    double width = 1.0,
  }) => Border.fromBorderSide(BorderSide(color: color, width: width));
}
''');
    super.setUp();
  }

  Future<void> test_borderAll_noArgs() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final border = Border.all();
''',
      [lint(55, 12)],
    );
  }

  Future<void> test_borderAll_withColor() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final border = Border.all(color: Color(0xFF000000));
''',
      [lint(55, 36)],
    );
  }

  Future<void> test_borderAll_withAllArgs() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final border = Border.all(
  color: Color(0xFF000000),
  width: 1.0,
  style: BorderStyle.solid,
);
''',
      [lint(55, 83)],
    );
  }

  Future<void> test_borderFromBorderSide() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
final border = Border.fromBorderSide(BorderSide());
''');
  }

  Future<void> test_borderFromBorderSide_withArgs() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
final border = Border.fromBorderSide(
  BorderSide(color: Color(0xFF000000), width: 1.0, style: BorderStyle.solid),
);
''');
  }

  // === Tests for visitMethodInvocation path (lines 65-74) ===

  Future<void> test_borderFactoryAll_noArgs_triggers() async {
    // BorderFactory.all() is a static method returning Border,
    // parsed as MethodInvocation (not InstanceCreationExpression)
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final border = BorderFactory.all();
''',
      [lint(55, 19)],
    );
  }

  Future<void> test_borderFactoryAll_withArgs_triggers() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final border = BorderFactory.all(color: Color(0xFF000000));
''',
      [lint(55, 43)],
    );
  }

  Future<void> test_methodInvocation_notAll_noLint() async {
    // Method name is not 'all' — should not trigger
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
final border = Border.fromBorderSide(BorderSide());
''');
  }

  Future<void> test_methodInvocation_nonSimpleIdentifierTarget_noLint() async {
    // Target is not a SimpleIdentifier (e.g., chained method call)
    // — line 70 early return
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
Border getFactory() => Border();
// getFactory().all would only work if Border had an 'all' instance method,
// but it doesn't — so we test a non-Border method call named 'all'
class Other {
  List<int> all() => [];
}
final result = Other().all();
''');
  }
}
