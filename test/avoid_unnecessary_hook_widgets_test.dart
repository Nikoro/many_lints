import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/avoid_unnecessary_hook_widgets.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidUnnecessaryHookWidgetsTest),
  );
}

@reflectiveTest
class AvoidUnnecessaryHookWidgetsTest extends ManyLintsRuleTest {
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
    newPackage('hooks_riverpod').addFile('lib/hooks_riverpod.dart', r'''
import 'package:flutter/widgets.dart';
class WidgetRef {
  T watch<T>(Object provider) => throw '';
}
class HookConsumerWidget extends Widget {
  Widget build(BuildContext context, WidgetRef ref) => Widget();
}
''');
    super.setUp();
  }

  Future<void> test_hook_widget_without_hooks() async {
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

  Future<void> test_hook_widget_with_hooks() async {
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

  Future<void> test_hook_widget_with_use_memoized() async {
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

  Future<void> test_stateless_widget() async {
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

  Future<void> test_hook_builder_without_hooks() async {
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

  Future<void> test_hook_builder_with_hooks() async {
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

  /// Overlap with `avoid_unnecessary_consumer_widgets`, which also reports a
  /// `HookConsumerWidget`. The two rules answer different questions — "does it
  /// use hooks?" versus "does it use ref?" — so both firing on a widget that
  /// uses neither is correct, and each reports at a different node.
  Future<void> test_hookConsumerWidget_withoutHooks() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
class MyWidget extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Widget();
  }
}
''',
      [lint(115, 18)],
    );
  }

  Future<void> test_hookConsumerWidget_withHooks_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
class MyWidget extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = useState(0);
    return Widget();
  }
}
''');
  }
}
