import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_explicit_function_type.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferExplicitFunctionTypeTest),
  );
}

@reflectiveTest
class PreferExplicitFunctionTypeTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferExplicitFunctionType();
    super.setUp();
  }

  Future<void> test_fieldDeclaration() async {
    await assertDiagnostics(
      r'''
class SomeWidget {
  final Function onTap;
  
  const SomeWidget(this.onTap);
}
''',
      [lint(27, 8)],
    );
  }

  Future<void> test_variableDeclaration() async {
    await assertDiagnostics(
      r'''
void foo() {
  Function callback;
}
''',
      [lint(15, 8)],
    );
  }

  Future<void> test_parameterDeclaration() async {
    await assertDiagnostics(
      r'''
void foo(Function callback) {}
''',
      [lint(9, 8)],
    );
  }

  Future<void> test_namedParameterDeclaration() async {
    await assertDiagnostics(
      r'''
void foo({required Function callback}) {}
''',
      [lint(19, 8)],
    );
  }

  Future<void> test_optionalParameterDeclaration() async {
    await assertDiagnostics(
      r'''
void foo([Function? callback]) {}
''',
      [lint(10, 9)],
    );
  }

  Future<void> test_returnType() async {
    await assertDiagnostics(
      r'''
Function getCallback() {
  return () {};
}
''',
      [lint(0, 8)],
    );
  }

  Future<void> test_nullable() async {
    await assertDiagnostics(
      r'''
class SomeWidget {
  final Function? onTap;
  
  const SomeWidget(this.onTap);
}
''',
      [lint(27, 9)],
    );
  }

  Future<void> test_typeArgument() async {
    await assertDiagnostics(
      r'''
void foo() {
  List<Function> callbacks = [];
}
''',
      [lint(20, 8)],
    );
  }

  // Valid cases - should not trigger lint

  Future<void> test_explicitFunctionType() async {
    await assertNoDiagnostics(r'''
class SomeWidget {
  final void Function() onTap;
  
  const SomeWidget(this.onTap);
}
''');
  }

  Future<void> test_explicitFunctionTypeWithParameters() async {
    await assertNoDiagnostics(r'''
class SomeWidget {
  final void Function(int value) onTap;
  
  const SomeWidget(this.onTap);
}
''');
  }

  Future<void> test_explicitFunctionTypeWithReturnType() async {
    await assertNoDiagnostics(r'''
class SomeWidget {
  final int Function() getValue;
  
  const SomeWidget(this.getValue);
}
''');
  }

  Future<void> test_explicitFunctionTypeNullable() async {
    await assertNoDiagnostics(r'''
class SomeWidget {
  final void Function()? onTap;
  
  const SomeWidget(this.onTap);
}
''');
  }
}
