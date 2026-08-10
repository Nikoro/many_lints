import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/never_discard_build_context.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(NeverDiscardBuildContextTest),
  );
}

@reflectiveTest
class NeverDiscardBuildContextTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NeverDiscardBuildContext();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {}
class BuildContext {}
class StatelessWidget extends Widget {
  Widget build(BuildContext context) => Widget();
}
class Builder extends Widget {
  Builder({required Widget Function(BuildContext context) builder});
}
class LayoutBuilder extends Widget {
  LayoutBuilder({required Widget Function(BuildContext context, Object constraints) builder});
}
class Text extends Widget {
  Text(String data);
}
''');
    super.setUp();
  }

  // --- Positive cases (should trigger lint) ---

  Future<void> test_discardedInBuilderCallback() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget f() => Builder(builder: (_) => Text('hi'));
''',
      [lint(72, 1)],
    );
  }

  Future<void> test_discardedInTypedCallback() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget f() => Builder(builder: (BuildContext _) => Text('hi'));
''',
      [lint(85, 1)],
    );
  }

  Future<void> test_discardedInTopLevelFunction() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget build(BuildContext _) => Text('hi');
''',
      [lint(66, 1)],
    );
  }

  Future<void> test_doubleUnderscoreAlsoDiscards() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget f() => LayoutBuilder(builder: (__, constraints) => Text('hi'));
''',
      [lint(78, 2)],
    );
  }

  // --- Negative cases (should NOT trigger lint) ---

  Future<void> test_namedContextIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget f() => Builder(builder: (context) => Text('hi'));
''');
  }

  Future<void> test_discardedNonContextParameter() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget f() => LayoutBuilder(builder: (context, _) => Text('hi'));
''');
  }

  Future<void> test_underscorePrefixedNameIsNotADiscard() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build(BuildContext _context) => Text('hi');
''');
  }

  // --- Edge cases ---

  Future<void> test_discardedNonContextTypeIsIgnored() async {
    await assertNoDiagnostics(r'''
void f(int _) {}
''');
  }

  Future<void> test_subtypeOfContextIsNotExactMatch() async {
    // Only an exact BuildContext is reported; a subclass has its own meaning
    // and renaming it is not obviously right.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyContext extends BuildContext {}

void f(MyContext _) {}
''');
  }
}
