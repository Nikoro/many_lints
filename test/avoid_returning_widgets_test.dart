import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_returning_widgets.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidReturningWidgetsTest));
}

@reflectiveTest
class AvoidReturningWidgetsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidReturningWidgets();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {
  const Widget({Key? key});
}
class Key {}
class BuildContext {}
class StatelessWidget extends Widget {
  const StatelessWidget({super.key});
  Widget build(BuildContext context) => Widget();
}
class StatefulWidget extends Widget {
  const StatefulWidget({super.key});
  State createState();
}
class State<T extends StatefulWidget> {
  T get widget => throw '';
  void setState(void Function() fn) {}
  Widget build(BuildContext context) => Widget();
}
class Container extends Widget {
  const Container({super.key, Widget? child});
}
class Text extends Widget {
  const Text(String data, {super.key});
}
''');
    super.setUp();
  }

  // --- Cases that SHOULD trigger the lint ---

  Future<void> test_methodReturningWidget_lint() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) => _buildBody();

  Widget _buildBody() {
    return Container();
  }
}
''',
      [lint(189, 10)],
    );
  }

  Future<void> test_getterReturningWidget_lint() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) => _body;

  Widget get _body => Container();
}
''',
      [lint(186, 5)],
    );
  }

  Future<void> test_topLevelFunctionReturningWidget_lint() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget buildGreeting() {
  return Text('Hello');
}
''',
      [lint(47, 13)],
    );
  }

  Future<void> test_staticMethodReturningWidget_lint() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class WidgetFactory {
  static Widget create() {
    return Container();
  }
}
''',
      [lint(78, 6)],
    );
  }

  Future<void> test_methodReturningWidgetSubclass_lint() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class Helper {
  Container makeContainer() {
    return Container();
  }
}
''',
      [lint(67, 13)],
    );
  }

  // --- Cases that should NOT trigger the lint ---

  Future<void> test_buildOverride_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) => Container();
}
''');
  }

  Future<void> test_methodReturningNonWidget_noLint() async {
    await assertNoDiagnostics(r'''
class Helper {
  String getName() => 'hello';
  int getCount() => 42;
}
''');
  }

  Future<void> test_methodReturningVoid_noLint() async {
    await assertNoDiagnostics(r'''
class Helper {
  void doSomething() {}
}
''');
  }

  Future<void> test_methodWithNoReturnType_noLint() async {
    await assertNoDiagnostics(r'''
class Helper {
  doSomething() {}
}
''');
  }

  Future<void> test_stateBuildOverride_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) => Container();
}
''');
  }

  Future<void> test_topLevelFunctionReturningString_noLint() async {
    await assertNoDiagnostics(r'''
String greet() => 'Hello';
''');
  }
}
