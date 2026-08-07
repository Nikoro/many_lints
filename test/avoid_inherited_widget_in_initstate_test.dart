import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_inherited_widget_in_initstate.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidInheritedWidgetInInitstateTest),
  );
}

@reflectiveTest
class AvoidInheritedWidgetInInitstateTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidInheritedWidgetInInitstate();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {}
class BuildContext {}
class StatefulWidget extends Widget {}
class State<T extends StatefulWidget> {
  void initState() {}
  void didChangeDependencies() {}
  void dispose() {}
}
class InheritedWidget extends Widget {}
class ThemeData {}
class Theme extends InheritedWidget {
  static ThemeData of(BuildContext context) => ThemeData();
}
class MediaQueryData {}
class MediaQuery extends InheritedWidget {
  static MediaQueryData of(BuildContext context) => MediaQueryData();
  static MediaQueryData? maybeOf(BuildContext context) => null;
}
''');
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_themeOfInInitState() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    final theme = Theme.of(context);
  }
}

BuildContext get context => throw '';
''',
      [lint(196, 17)],
    );
  }

  Future<void> test_mediaQueryMaybeOfInInitState() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  @override
  void initState() {
    final data = MediaQuery.maybeOf(context);
  }
}

BuildContext get context => throw '';
''',
      [lint(172, 27)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_themeOfInDidChangeDependencies() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
  }
}

BuildContext get context => throw '';
''');
  }

  Future<void> test_themeOfInBuild() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Widget();
  }
}
''');
  }

  Future<void> test_nonInheritedWidgetOfCall() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyService {
  static MyService of(BuildContext context) => MyService();
}

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  @override
  void initState() {
    // MyService is not an InheritedWidget — no lint
    final service = MyService.of(context);
  }
}

BuildContext get context => throw '';
''');
  }

  Future<void> test_initStateInNonStateClass() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class NotAState {
  void initState() {
    final theme = Theme.of(context);
  }
}

BuildContext get context => throw '';
''');
  }

  Future<void> test_instanceOfMethodNotOnType() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Locator {
  ThemeData of(BuildContext context) => ThemeData();
}

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  final locator = Locator();

  @override
  void initState() {
    // Instance call, not a static InheritedWidget lookup — no lint
    final theme = locator.of(context);
  }
}

BuildContext get context => throw '';
''');
  }
}
