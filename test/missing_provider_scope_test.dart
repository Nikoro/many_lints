import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/missing_provider_scope.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(MissingProviderScopeTest));
}

@reflectiveTest
class MissingProviderScopeTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = MissingProviderScope();

    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {}
class BuildContext {}
class StatelessWidget extends Widget {
  Widget build(BuildContext context) => Widget();
}
void runApp(Widget app) {}
''');

    newPackage('flutter_riverpod').addFile('lib/flutter_riverpod.dart', r'''
import 'package:flutter/widgets.dart';
class ProviderContainer {}
class ProviderScope extends Widget {
  ProviderScope({Widget? child});
}
class UncontrolledProviderScope extends Widget {
  UncontrolledProviderScope({required ProviderContainer container, Widget? child});
}
''');

    super.setUp();
  }

  // --- Positive cases: should trigger lint ---

  Future<void> test_runAppWithoutProviderScope() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyApp extends StatelessWidget {}

void main() {
  runApp(MyApp());
}
''',
      [lint(96, 6)],
    );
  }

  Future<void> test_runAppWithNonScopeWrapper() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyApp extends StatelessWidget {}
class Wrapper extends StatelessWidget {
  Wrapper({Widget? child});
}

void main() {
  runApp(Wrapper(child: MyApp()));
}
''',
      [lint(166, 6)],
    );
  }

  // --- Negative cases: should not trigger lint ---

  Future<void> test_runAppWithProviderScope() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends StatelessWidget {}

void main() {
  runApp(ProviderScope(child: MyApp()));
}
''');
  }

  Future<void> test_runAppWithUncontrolledProviderScope() async {
    // An externally-owned container is a legitimate way to install the scope.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends StatelessWidget {}

void main() {
  runApp(UncontrolledProviderScope(
    container: ProviderContainer(),
    child: MyApp(),
  ));
}
''');
  }

  Future<void> test_localRunAppNotFlagged() async {
    // A same-named function that is not Flutter's runApp.
    await assertNoDiagnostics(r'''
class Widget {}
class MyApp extends Widget {}

void runApp(Widget app) {}

void main() {
  runApp(MyApp());
}
''');
  }

  Future<void> test_runAppWithNoArguments() async {
    await assertNoDiagnostics(r'''
void runApp() {}

void main() {
  runApp();
}
''');
  }
}
