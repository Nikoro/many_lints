import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_empty_setstate.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidEmptySetstateTest));
}

@reflectiveTest
class AvoidEmptySetstateTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidEmptySetstate();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {
  const Widget();
}
class BuildContext {}
class StatefulWidget extends Widget {
  const StatefulWidget();
}
class State<T extends StatefulWidget> {
  void setState(void Function() fn) {}
  void initState() {}
  void dispose() {}
  Widget build(BuildContext context) => const Widget();
}
''');
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_emptySetState() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  int counter = 0;

  void increment() {
    counter++;
    setState(() {});
  }
}
''',
      [lint(182, 15)],
    );
  }

  Future<void> test_emptySetStateWithThis() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  void refresh() {
    this.setState(() {});
  }
}
''',
      [lint(145, 20)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_setStateWithMutation() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  int counter = 0;

  void increment() {
    setState(() {
      counter++;
    });
  }
}
''');
  }

  Future<void> test_setStateWithExpressionBody() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  int counter = 0;

  void increment() {
    setState(() => counter++);
  }
}
''');
  }

  Future<void> test_setStateOnUnrelatedClass() async {
    await assertNoDiagnostics(r'''
class NotAState {
  void setState(void Function() fn) {}

  void refresh() {
    setState(() {});
  }
}
''');
  }

  Future<void> test_setStateOnOtherObject() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Helper {
  void setState(void Function() fn) {}
}

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  final helper = Helper();

  void refresh() {
    helper.setState(() {});
  }
}
''');
  }

  Future<void> test_setStateWithNoOpStatement() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  int counter = 0;

  void refresh() {
    setState(() {
      // A statement is present — the rule does not judge its effect
      counter = counter;
    });
  }
}
''');
  }
}
