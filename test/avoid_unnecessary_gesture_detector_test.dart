import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_unnecessary_gesture_detector.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidUnnecessaryGestureDetectorTest),
  );
}

@reflectiveTest
class AvoidUnnecessaryGestureDetectorTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryGestureDetector();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {
  const Widget({Key? key});
}

class Key {}

class GestureDetector extends Widget {
  const GestureDetector({
    super.key,
    Widget? child,
    void Function()? onTap,
    void Function()? onTapDown,
    void Function()? onTapUp,
    void Function()? onTapCancel,
    void Function()? onDoubleTap,
    void Function()? onLongPress,
    void Function()? onVerticalDragStart,
    void Function()? onHorizontalDragStart,
    void Function()? onPanStart,
    void Function()? onScaleStart,
    int? behavior,
  });
}

class Text extends Widget {
  const Text(String data);
}

class Container extends Widget {
  const Container({super.key, Widget? child});
}
''');
    super.setUp();
  }

  Future<void> test_gestureDetectorWithNoHandlers() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return GestureDetector(
    child: Text('hello'),
  );
}
''',
      [lint(61, 15)],
    );
  }

  Future<void> test_gestureDetectorWithOnlyChild() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return GestureDetector(child: Container());
}
''',
      [lint(61, 15)],
    );
  }

  Future<void> test_gestureDetectorWithNoArguments() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return GestureDetector();
}
''',
      [lint(61, 15)],
    );
  }

  Future<void> test_gestureDetectorWithBehaviorOnly() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return GestureDetector(
    behavior: 1,
    child: Text('hello'),
  );
}
''',
      [lint(61, 15)],
    );
  }

  Future<void> test_gestureDetectorWithOnTap() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return GestureDetector(
    onTap: () {},
    child: Text('hello'),
  );
}
''');
  }

  Future<void> test_gestureDetectorWithOnLongPress() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return GestureDetector(
    onLongPress: () {},
    child: Text('hello'),
  );
}
''');
  }

  Future<void> test_gestureDetectorWithOnDoubleTap() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return GestureDetector(
    onDoubleTap: () {},
    child: Text('hello'),
  );
}
''');
  }

  Future<void> test_gestureDetectorWithOnPanStart() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return GestureDetector(
    onPanStart: () {},
    child: Text('hello'),
  );
}
''');
  }

  Future<void> test_gestureDetectorWithMultipleHandlers() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return GestureDetector(
    onTap: () {},
    onLongPress: () {},
    child: Text('hello'),
  );
}
''');
  }
}
