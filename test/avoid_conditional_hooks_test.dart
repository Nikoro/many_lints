import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_conditional_hooks.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidConditionalHooksTest));
}

@reflectiveTest
class AvoidConditionalHooksTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidConditionalHooks();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {}
class BuildContext {}
class StatelessWidget extends Widget {
  Widget build(BuildContext context) => Widget();
}
''');
    newPackage('flutter_hooks').addFile('lib/flutter_hooks.dart', r'''
import 'package:flutter/widgets.dart';
class HookWidget extends Widget {
  Widget build(BuildContext context) => Widget();
}
T useState<T>(T initialData) => initialData;
T useMemoized<T>(T Function() valueBuilder) => valueBuilder();
class HookBuilder extends Widget {
  HookBuilder({required Widget Function(BuildContext) builder});
}
''');
    newPackage('hooks_riverpod').addFile('lib/hooks_riverpod.dart', r'''
import 'package:flutter/widgets.dart';
class HookConsumerWidget extends Widget {
  Widget build(BuildContext context) => Widget();
}
''');
    super.setUp();
  }

  // --- Positive cases: should trigger the lint ---

  Future<void> test_hookInsideIfStatement() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
class MyWidget extends HookWidget {
  final bool condition;
  MyWidget(this.condition);
  @override
  Widget build(BuildContext context) {
    if (condition) {
      useState(0);
    }
    return Widget();
  }
}
''',
      [lint(256, 11)],
    );
  }

  Future<void> test_hookInsideElseBranch() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
class MyWidget extends HookWidget {
  final bool condition;
  MyWidget(this.condition);
  @override
  Widget build(BuildContext context) {
    if (condition) {
      // no hook here
    } else {
      useState(0);
    }
    return Widget();
  }
}
''',
      [lint(291, 11)],
    );
  }

  Future<void> test_hookInsideTernary() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
class MyWidget extends HookWidget {
  final bool condition;
  MyWidget(this.condition);
  @override
  Widget build(BuildContext context) {
    final value = condition ? useState(0) : useState(1);
    return Widget();
  }
}
''',
      [lint(259, 11), lint(273, 11)],
    );
  }

  Future<void> test_hookInsideSwitchStatement() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
class MyWidget extends HookWidget {
  final int value;
  MyWidget(this.value);
  @override
  Widget build(BuildContext context) {
    switch (value) {
      case 0:
        useState(0);
        break;
      default:
        break;
    }
    return Widget();
  }
}
''',
      [lint(263, 11)],
    );
  }

  Future<void> test_hookInsideLogicalAnd() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
class MyWidget extends HookWidget {
  final bool condition;
  MyWidget(this.condition);
  @override
  Widget build(BuildContext context) {
    final x = condition && useMemoized(() => true);
    return Widget();
  }
}
''',
      [lint(256, 23)],
    );
  }

  Future<void> test_hookInsideHookBuilderConditional() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
Widget f(bool condition) {
  return HookBuilder(builder: (context) {
    if (condition) {
      useState(0);
    }
    return Widget();
  });
}
''',
      [lint(186, 11)],
    );
  }

  // --- Negative cases: should NOT trigger the lint ---

  Future<void> test_unconditionalHookCall() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
class MyWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final value = useState(0);
    return Widget();
  }
}
''');
  }

  Future<void> test_hookWithConditionalLogicInside() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
class MyWidget extends HookWidget {
  final bool condition;
  MyWidget(this.condition);
  @override
  Widget build(BuildContext context) {
    final value = useMemoized(() {
      if (condition) {
        return 42;
      }
      return 0;
    });
    return Widget();
  }
}
''');
  }

  Future<void> test_statelessWidgetNotChecked() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  final bool condition;
  MyWidget(this.condition);
  @override
  Widget build(BuildContext context) {
    if (condition) {
      // regular code
    }
    return Widget();
  }
}
''');
  }

  Future<void> test_nonHookMethodInsideIf() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
class MyWidget extends HookWidget {
  final bool condition;
  MyWidget(this.condition);
  @override
  Widget build(BuildContext context) {
    final value = useState(0);
    if (condition) {
      print(value);
    }
    return Widget();
  }
}
''');
  }

  Future<void> test_hookInsideNestedClosure() async {
    // Hooks inside closures (callbacks) are a different scope, not flagged
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
class MyWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final value = useState(0);
    final callback = () {
      useState(1);
    };
    return Widget();
  }
}
''');
  }

  Future<void> test_multipleUnconditionalHooks() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
class MyWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final a = useState(0);
    final b = useMemoized(() => 42);
    return Widget();
  }
}
''');
  }

  // --- HookConsumerWidget tests ---

  Future<void> test_hookConsumerWidgetInsideIf() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
class MyWidget extends HookConsumerWidget {
  final bool condition;
  MyWidget(this.condition);
  @override
  Widget build(BuildContext context) {
    if (condition) {
      useState(0);
    }
    return Widget();
  }
}
''',
      [lint(317, 11)],
    );
  }

  // --- Logical || operator tests ---

  Future<void> test_hookInsideLogicalOr() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
class MyWidget extends HookWidget {
  final bool condition;
  MyWidget(this.condition);
  @override
  Widget build(BuildContext context) {
    final x = condition || useMemoized(() => false);
    return Widget();
  }
}
''',
      [lint(256, 24)],
    );
  }

  // --- Switch expression tests ---

  Future<void> test_hookInsideSwitchExpression() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
class MyWidget extends HookWidget {
  final int value;
  MyWidget(this.value);
  @override
  Widget build(BuildContext context) {
    final result = switch (value) {
      0 => useState(0),
      _ => useState(1),
    };
    return Widget();
  }
}
''',
      [lint(267, 11), lint(291, 11)],
    );
  }
}
