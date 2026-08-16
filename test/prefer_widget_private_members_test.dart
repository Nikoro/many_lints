import 'package:many_lints/src/rules/prefer_widget_private_members.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferWidgetPrivateMembersTest),
  );
}

@reflectiveTest
class PreferWidgetPrivateMembersTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferWidgetPrivateMembers();
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
class State<T extends StatefulWidget> {
  T get widget => throw '';
  Widget build(BuildContext context) => Widget();
}
class StatefulWidget extends Widget {
  const StatefulWidget({super.key});
  State createState();
}
''');
    super.setUp();
  }

  Future<void> test_publicMethodOnWidget() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  void refresh() {}

  @override
  Widget build(BuildContext context) => Widget();
}
''',
      [lint(120, 7)],
    );
  }

  Future<void> test_privateMethodIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  void _refresh() {}

  @override
  Widget build(BuildContext context) => Widget();
}
''');
  }

  // `build` is the framework's, so it cannot be private.
  Future<void> test_frameworkMemberIsExempt() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) => Widget();
}
''');
  }

  // A widget's fields are its constructor parameters, and public finals are
  // the idiom the framework itself uses.
  Future<void> test_publicFieldIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Widget();
}
''');
  }

  // A static member is not reachable on a widget instance, so the rebuild
  // argument does not apply. `static Future<T> show(context)` is the
  // documented way to open a dialog, and was 14 of 16 reports on a real app.
  Future<void> test_staticEntryPointIsExempt() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyDialog extends StatelessWidget {
  const MyDialog({super.key});

  static void show(BuildContext context) {}

  @override
  Widget build(BuildContext context) => Widget();
}
''');
  }

  // A non-widget class is out of scope entirely.
  Future<void> test_nonWidgetClassIsIgnored() async {
    await assertNoDiagnostics(r'''
class Service {
  void refresh() {}
}
''');
  }

  Future<void> test_visibleForTestingIsExempt() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class VisibleForTesting {
  const VisibleForTesting();
}

const visibleForTesting = VisibleForTesting();

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @visibleForTesting
  void refresh() {}

  @override
  Widget build(BuildContext context) => Widget();
}
''');
  }
}
