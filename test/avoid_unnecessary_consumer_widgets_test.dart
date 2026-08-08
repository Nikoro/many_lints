import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_unnecessary_consumer_widgets.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidUnnecessaryConsumerWidgetsTest),
  );
}

@reflectiveTest
class AvoidUnnecessaryConsumerWidgetsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryConsumerWidgets();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {}
class BuildContext {}
class StatelessWidget extends Widget {
  Widget build(BuildContext context) => Widget();
}
class StatefulWidget extends Widget {
  State createState() => throw '';
}
class State<T extends StatefulWidget> {
  Widget build(BuildContext context) => Widget();
  void setState(void Function() fn) {}
}
''');
    newPackage('flutter_riverpod').addFile('lib/flutter_riverpod.dart', r'''
import 'package:flutter/widgets.dart';
class WidgetRef {
  T watch<T>(Object provider) => throw '';
  T read<T>(Object provider) => throw '';
}
class ConsumerWidget extends Widget {
  Widget build(BuildContext context, WidgetRef ref) => Widget();
}
class ConsumerStatefulWidget extends StatefulWidget {}
class ConsumerState<T extends ConsumerStatefulWidget> extends State<T> {
  WidgetRef get ref => throw '';
}
''');
    newPackage('hooks_riverpod').addFile('lib/hooks_riverpod.dart', r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class HookConsumerWidget extends Widget {
  Widget build(BuildContext context, WidgetRef ref) => Widget();
}
class HookConsumerState<T extends ConsumerStatefulWidget> extends State<T> {
  WidgetRef get ref => throw '';
}
''');
    super.setUp();
  }

  Future<void> test_consumer_widget_without_ref() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Widget();
  }
}
''',
      [lint(102, 8)],
    );
  }

  Future<void> test_consumer_widget_with_ref() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref;
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

  Future<void> test_consumerStatefulWidget_withoutRef_lint() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class MyWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyWidget> createState() => _MyWidgetState();
}
class _MyWidgetState extends ConsumerState<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return Widget();
  }
}
''',
      [lint(102, 8)],
    );
  }

  Future<void> test_consumerStatefulWidget_refInBuild_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class MyWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyWidget> createState() => _MyWidgetState();
}
class _MyWidgetState extends ConsumerState<MyWidget> {
  @override
  Widget build(BuildContext context) {
    ref.watch(Object());
    return Widget();
  }
}
''');
  }

  /// `ref` is a getter on the State, so a use outside `build` counts too.
  Future<void> test_consumerStatefulWidget_refOutsideBuild_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class MyWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyWidget> createState() => _MyWidgetState();
}
class _MyWidgetState extends ConsumerState<MyWidget> {
  void _onTap() {
    ref.read(Object());
  }

  @override
  Widget build(BuildContext context) {
    return Widget();
  }
}
''');
  }

  Future<void> test_consumerStatefulWidget_localMixinUsesRef_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

mixin AnalyticsMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  void track() {
    ref.read(Object());
  }
}

class MyWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyWidget> createState() => _MyWidgetState();
}
class _MyWidgetState extends ConsumerState<MyWidget> with AnalyticsMixin {
  @override
  Widget build(BuildContext context) {
    return Widget();
  }
}
''');
  }

  /// A mixin that carries no `ref` usage must not mask the diagnostic.
  Future<void> test_consumerStatefulWidget_localMixinWithoutRef_lint() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

mixin LabelMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  String get label => 'hi';
}

class MyWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyWidget> createState() => _MyWidgetState();
}
class _MyWidgetState extends ConsumerState<MyWidget> with LabelMixin {
  @override
  Widget build(BuildContext context) {
    return Widget();
  }
}
''',
      [lint(207, 8)],
    );
  }

  Future<void> test_consumerStatefulWidget_externalMixin_noLint() async {
    newFile('$testPackageLibPath/analytics_mixin.dart', r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

mixin AnalyticsMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  void track() {
    ref.read(Object());
  }
}
''');
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_mixin.dart';

class MyWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyWidget> createState() => _MyWidgetState();
}
class _MyWidgetState extends ConsumerState<MyWidget> with AnalyticsMixin {
  @override
  Widget build(BuildContext context) {
    return Widget();
  }
}
''');
  }

  Future<void> test_consumerWidget_localMixinUsesRef_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

mixin GreetingMixin {
  Widget greet(WidgetRef ref) {
    ref.watch(Object());
    return Widget();
  }
}

class MyWidget extends ConsumerWidget with GreetingMixin {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Widget();
  }
}
''');
  }

  Future<void> test_hookConsumerWidget_withoutRef() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
class MyWidget extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Widget();
  }
}
''',
      [lint(155, 8)],
    );
  }

  Future<void> test_hookConsumerWidget_usesRef_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
class MyWidget extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(Object());
    return Widget();
  }
}
''');
  }
}
