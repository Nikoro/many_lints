import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/always_pass_global_key.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AlwaysPassGlobalKeyTest));
}

@reflectiveTest
class AlwaysPassGlobalKeyTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AlwaysPassGlobalKey();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class BuildContext {}
class Key {}
class GlobalKey<T> extends Key {}
class Widget {
  const Widget({this.key});
  final Key? key;
}
class StatelessWidget extends Widget {
  const StatelessWidget({super.key});
  Widget build(BuildContext context) => this;
}
class StatefulWidget extends Widget {
  const StatefulWidget({super.key});
}
class State<T extends StatefulWidget> {
  Widget build(BuildContext context) => Widget();
}
class FormState {}
''');
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_globalKeyInBuild() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final key = GlobalKey<FormState>();
    return Widget(key: key);
  }
}
''',
      [lint(148, 22)],
    );
  }

  Future<void> test_globalKeyInlineInBuild() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Widget(key: GlobalKey<FormState>());
  }
}
''',
      [lint(155, 22)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_globalKeyAsStateField() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  final _key = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Widget(key: _key);
  }
}
''');
  }

  Future<void> test_plainKeyInBuildIsIgnored() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Widget(key: Key());
  }
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_globalKeyOutsideBuildIsIgnored() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Holder {
  GlobalKey<FormState> create() => GlobalKey<FormState>();
}
''');
  }

  Future<void> test_globalKeyInStateBuild() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    final key = GlobalKey<FormState>();
    return Widget(key: key);
  }
}
''',
      [lint(189, 22)],
    );
  }
}
