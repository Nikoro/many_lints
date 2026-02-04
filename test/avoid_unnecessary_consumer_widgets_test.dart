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
''');
    newPackage('flutter_riverpod').addFile('lib/flutter_riverpod.dart', r'''
import 'package:flutter/widgets.dart';
class WidgetRef {}
class ConsumerWidget extends Widget {
  Widget build(BuildContext context, WidgetRef ref) => Widget();
}
''');
    super.setUp();
  }

  Future<void> test_consumerWidgetWithoutRef() async {
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

  Future<void> test_consumerWidgetWithRef() async {
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
}
