import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_unnecessary_hook_widgets.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
      () => defineReflectiveTests(AvoidUnnecessaryHookWidgetsTest));
}

@reflectiveTest
class AvoidUnnecessaryHookWidgetsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryHookWidgets();
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
    super.setUp();
  }

  Future<void> test_hookWidgetWithoutHooks() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
class MyWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    return Widget();
  }
}
''',
      [lint(113, 10)],
    );
  }

  Future<void> test_hookWidgetWithHooks() async {
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

  Future<void> test_hookWidgetWithUseMemoized() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
class MyWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final value = useMemoized(() => 42);
    return Widget();
  }
}
''');
  }

  Future<void> test_statelessWidget() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Widget();
  }
}
''');
  }

  Future<void> test_hookBuilderWithoutHooks() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
Widget f() {
  return HookBuilder(builder: (context) {
    return Widget();
  });
}
''',
      [lint(112, 11)],
    );
  }

  Future<void> test_hookBuilderWithHooks() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
Widget f() {
  return HookBuilder(builder: (context) {
    final value = useState(0);
    return Widget();
  });
}
''');
  }
}
