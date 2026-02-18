import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_single_widget_per_file.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferSingleWidgetPerFileTest),
  );
}

@reflectiveTest
class PreferSingleWidgetPerFileTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferSingleWidgetPerFile();
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
''');
    super.setUp();
  }

  Future<void> test_singlePublicWidget_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) => Widget();
}
''');
  }

  Future<void> test_twoPublicWidgets_lintsSecond() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class FirstWidget extends StatelessWidget {
  const FirstWidget({super.key});

  @override
  Widget build(BuildContext context) => Widget();
}

class SecondWidget extends StatelessWidget {
  const SecondWidget({super.key});

  @override
  Widget build(BuildContext context) => Widget();
}
''',
      [lint(190, 12)],
    );
  }

  Future<void> test_threePublicWidgets_lintsSecondAndThird() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class FirstWidget extends StatelessWidget {
  const FirstWidget({super.key});

  @override
  Widget build(BuildContext context) => Widget();
}

class SecondWidget extends StatelessWidget {
  const SecondWidget({super.key});

  @override
  Widget build(BuildContext context) => Widget();
}

class ThirdWidget extends StatelessWidget {
  const ThirdWidget({super.key});

  @override
  Widget build(BuildContext context) => Widget();
}
''',
      [lint(190, 12), lint(336, 11)],
    );
  }

  Future<void> test_publicAndPrivateWidgets_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) => Widget();
}

class _PrivateWidget extends StatelessWidget {
  const _PrivateWidget();

  @override
  Widget build(BuildContext context) => Widget();
}
''');
  }

  Future<void> test_multiplePrivateWidgets_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class _FirstPrivate extends StatelessWidget {
  const _FirstPrivate();

  @override
  Widget build(BuildContext context) => Widget();
}

class _SecondPrivate extends StatelessWidget {
  const _SecondPrivate();

  @override
  Widget build(BuildContext context) => Widget();
}
''');
  }

  Future<void> test_publicWidgetWithPrivateState_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) => Widget();
}
''');
  }

  Future<void> test_twoPublicStatefulWidgets_lintsSecond() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class FirstWidget extends StatefulWidget {
  const FirstWidget({super.key});

  @override
  State<FirstWidget> createState() => _FirstWidgetState();
}

class _FirstWidgetState extends State<FirstWidget> {
  @override
  Widget build(BuildContext context) => Widget();
}

class SecondWidget extends StatefulWidget {
  const SecondWidget({super.key});

  @override
  State<SecondWidget> createState() => _SecondWidgetState();
}

class _SecondWidgetState extends State<SecondWidget> {
  @override
  Widget build(BuildContext context) => Widget();
}
''',
      [lint(316, 12)],
    );
  }

  Future<void> test_nonWidgetClasses_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) => Widget();
}

class NotAWidget {
  const NotAWidget();
}

class AnotherNonWidget {
  const AnotherNonWidget();
}
''');
  }

  Future<void> test_twoPublicWidgetsWithPrivate_lintsSecondPublic() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class FirstWidget extends StatelessWidget {
  const FirstWidget({super.key});

  @override
  Widget build(BuildContext context) => Widget();
}

class _HelperWidget extends StatelessWidget {
  const _HelperWidget();

  @override
  Widget build(BuildContext context) => Widget();
}

class SecondWidget extends StatelessWidget {
  const SecondWidget({super.key});

  @override
  Widget build(BuildContext context) => Widget();
}
''',
      [lint(327, 12)],
    );
  }
}
