import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_void_callback.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferVoidCallbackTest));
}

@reflectiveTest
class PreferVoidCallbackTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferVoidCallback();
    super.setUp();
  }

  // Positive cases - should trigger lint

  Future<void> test_fieldDeclaration() async {
    await assertDiagnostics(
      r'''
class MyWidget {
  final void Function() onTap;
  const MyWidget(this.onTap);
}
''',
      [lint(25, 15)],
    );
  }

  Future<void> test_variableDeclaration() async {
    await assertDiagnostics(
      r'''
void foo() {
  void Function() callback = () {};
}
''',
      [lint(15, 15)],
    );
  }

  Future<void> test_parameterDeclaration() async {
    await assertDiagnostics(
      r'''
void foo(void Function() callback) {}
''',
      [lint(9, 15)],
    );
  }

  Future<void> test_namedParameter() async {
    await assertDiagnostics(
      r'''
void foo({required void Function() callback}) {}
''',
      [lint(19, 15)],
    );
  }

  Future<void> test_nullable() async {
    await assertDiagnostics(
      r'''
class MyWidget {
  final void Function()? onTap;
  const MyWidget(this.onTap);
}
''',
      [lint(25, 16)],
    );
  }

  Future<void> test_typeArgument() async {
    await assertDiagnostics(
      r'''
void foo() {
  List<void Function()> callbacks = [];
}
''',
      [lint(20, 15)],
    );
  }

  Future<void> test_returnType() async {
    await assertDiagnostics(
      r'''
void Function() getCallback() {
  return () {};
}
''',
      [lint(0, 15)],
    );
  }

  // Negative cases - should NOT trigger lint

  Future<void> test_voidCallbackTypedef() async {
    await assertNoDiagnostics(r'''
typedef VoidCallback = void Function();
void foo(VoidCallback callback) {}
''');
  }

  Future<void> test_voidFunctionWithParameters() async {
    await assertNoDiagnostics(r'''
void foo(void Function(int value) callback) {}
''');
  }

  Future<void> test_intFunction() async {
    await assertNoDiagnostics(r'''
void foo(int Function() callback) {}
''');
  }

  Future<void> test_futureVoidFunction() async {
    await assertNoDiagnostics(r'''
void foo(Future<void> Function() callback) {}
''');
  }

  Future<void> test_voidFunctionWithTypeParameters() async {
    await assertNoDiagnostics(r'''
void foo(void Function<T>() callback) {}
''');
  }

  Future<void> test_forLoopVariable() async {
    await assertDiagnostics(
      r'''
void foo(List<void Function()> callbacks) {
  for (final void Function() callback in callbacks) {
    callback();
  }
}
''',
      [lint(14, 15), lint(57, 15)],
    );
  }
}
