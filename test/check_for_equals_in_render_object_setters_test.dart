import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/check_for_equals_in_render_object_setters.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(CheckForEqualsInRenderObjectSettersTest),
  );
}

@reflectiveTest
class CheckForEqualsInRenderObjectSettersTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = CheckForEqualsInRenderObjectSetters();
    newPackage('flutter').addFile('lib/rendering.dart', r'''
class RenderObject {
  void markNeedsLayout() {}
  void markNeedsPaint() {}
  void markNeedsSemanticsUpdate() {}
}
class RenderBox extends RenderObject {}
''');
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_setterWithoutEqualityCheck() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/rendering.dart';

class MyRender extends RenderBox {
  int _value = 0;

  set value(int value) {
    _value = value;
    markNeedsPaint();
  }
}
''',
      [lint(102, 5)],
    );
  }

  Future<void> test_markNeedsLayoutWithoutCheck() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/rendering.dart';

class MyRender extends RenderBox {
  double _width = 0;

  set width(double width) {
    _width = width;
    markNeedsLayout();
  }
}
''',
      [lint(105, 5)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_setterWithEarlyReturnGuard() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/rendering.dart';

class MyRender extends RenderBox {
  int _value = 0;

  set value(int value) {
    if (_value == value) return;
    _value = value;
    markNeedsPaint();
  }
}
''');
  }

  Future<void> test_setterWithNotEqualGuard() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/rendering.dart';

class MyRender extends RenderBox {
  int _value = 0;

  set value(int value) {
    if (_value != value) {
      _value = value;
      markNeedsPaint();
    }
  }
}
''');
  }

  Future<void> test_setterWithoutMarkDirty() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/rendering.dart';

class MyRender extends RenderBox {
  int _value = 0;

  set value(int value) {
    _value = value;
  }
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_nonRenderObjectIsIgnored() async {
    await assertNoDiagnostics(r'''
class NotARender {
  int _value = 0;

  void markNeedsPaint() {}

  set value(int value) {
    _value = value;
    markNeedsPaint();
  }
}
''');
  }

  Future<void> test_identicalCountsAsGuard() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/rendering.dart';

class MyRender extends RenderBox {
  Object _value = 0;

  set value(Object value) {
    if (identical(_value, value)) return;
    _value = value;
    markNeedsPaint();
  }
}
''');
  }

  Future<void> test_getterIsIgnored() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/rendering.dart';

class MyRender extends RenderBox {
  int _value = 0;

  int get value {
    markNeedsPaint();
    return _value;
  }
}
''');
  }
}
