import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_async_callback.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferAsyncCallbackTest));
}

@reflectiveTest
class PreferAsyncCallbackTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferAsyncCallback();
    super.setUp();
  }

  // Positive cases - should trigger lint

  Future<void> test_fieldDeclaration() async {
    await assertDiagnostics(
      r'''
class MyWidget {
  final Future<void> Function() onTap;
  const MyWidget(this.onTap);
}
''',
      [lint(25, 23)],
    );
  }

  Future<void> test_variableDeclaration() async {
    await assertDiagnostics(
      r'''
void foo() {
  Future<void> Function() callback = () async {};
}
''',
      [lint(15, 23)],
    );
  }

  Future<void> test_parameterDeclaration() async {
    await assertDiagnostics(
      r'''
void foo(Future<void> Function() callback) {}
''',
      [lint(9, 23)],
    );
  }

  Future<void> test_namedParameter() async {
    await assertDiagnostics(
      r'''
void foo({required Future<void> Function() callback}) {}
''',
      [lint(19, 23)],
    );
  }

  Future<void> test_nullable() async {
    await assertDiagnostics(
      r'''
class MyWidget {
  final Future<void> Function()? onTap;
  const MyWidget(this.onTap);
}
''',
      [lint(25, 24)],
    );
  }

  Future<void> test_typeArgument() async {
    await assertDiagnostics(
      r'''
void foo() {
  List<Future<void> Function()> callbacks = [];
}
''',
      [lint(20, 23)],
    );
  }

  Future<void> test_returnType() async {
    await assertDiagnostics(
      r'''
Future<void> Function() getCallback() {
  return () async {};
}
''',
      [lint(0, 23)],
    );
  }

  // Negative cases - should NOT trigger lint

  Future<void> test_asyncCallbackTypedef() async {
    await assertNoDiagnostics(r'''
typedef AsyncCallback = Future<void> Function();
void foo(AsyncCallback callback) {}
''');
  }

  Future<void> test_futureVoidFunctionWithParameters() async {
    await assertNoDiagnostics(r'''
void foo(Future<void> Function(int value) callback) {}
''');
  }

  Future<void> test_futureIntFunction() async {
    await assertNoDiagnostics(r'''
void foo(Future<int> Function() callback) {}
''');
  }

  Future<void> test_futureStringFunction() async {
    await assertNoDiagnostics(r'''
void foo(Future<String> Function() callback) {}
''');
  }

  Future<void> test_voidCallback() async {
    await assertNoDiagnostics(r'''
void foo(void Function() callback) {}
''');
  }

  Future<void> test_futureWithoutTypeArg() async {
    await assertNoDiagnostics(r'''
void foo(Future Function() callback) {}
''');
  }

  Future<void> test_futureVoidFunctionWithTypeParameters() async {
    await assertNoDiagnostics(r'''
void foo(Future<void> Function<T>() callback) {}
''');
  }
}
