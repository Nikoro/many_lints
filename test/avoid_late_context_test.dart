import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_late_context.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidLateContextTest));
}

@reflectiveTest
class AvoidLateContextTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidLateContext();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {}
class BuildContext {}
class StatefulWidget extends Widget {}
class State<T extends StatefulWidget> {
  BuildContext get context => BuildContext();
  void initState() {}
  void dispose() {}
}
class ThemeData {
  double get size => 1;
}
class Theme {
  static ThemeData of(BuildContext context) => ThemeData();
}
''');
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_lateFieldReadsContext() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  late final theme = Theme.of(context);
}
''',
      [lint(135, 25)],
    );
  }

  Future<void> test_lateFieldReadsContextIndirectly() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  late final size = Theme.of(context).size;
}
''',
      [lint(135, 29)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_nonLateFieldIsIgnored() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  ThemeData? theme;

  @override
  void initState() {
    theme = Theme.of(context);
  }
}
''');
  }

  Future<void> test_lateFieldWithoutContext() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  late final value = 42;
}
''');
  }

  Future<void> test_lateFieldWithNoInitializer() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  late final ThemeData theme;
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_outsideStateIsIgnored() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Helper {
  late final value = _read(BuildContext());

  int _read(BuildContext context) => 1;
}
''');
  }

  Future<void> test_staticLateFieldIsIgnored() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  static late final int value = 42;
}
''');
  }
}
