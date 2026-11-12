import 'package:many_lints/src/rules/prefer_correct_callback_field_name.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferCorrectCallbackFieldNameTest),
  );
}

@reflectiveTest
class PreferCorrectCallbackFieldNameTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferCorrectCallbackFieldName();
    super.setUp();
  }

  Future<void> test_callbackSuffixOnField() async {
    await assertDiagnostics(
      r'''
class A {
  final void Function() tapCallback = _noop;
}

void _noop() {}
''',
      [lint(34, 11)],
    );
  }

  Future<void> test_handlerSuffixOnField() async {
    await assertDiagnostics(
      r'''
class A {
  final void Function() submitHandler = _noop;
}

void _noop() {}
''',
      [lint(34, 13)],
    );
  }

  Future<void> test_listenerSuffixOnParameter() async {
    await assertDiagnostics(
      r'''
void configure(void Function() changeListener) {}
''',
      [lint(31, 14)],
    );
  }

  Future<void> test_onPrefixedName() async {
    await assertNoDiagnostics(r'''
class A {
  final void Function() onTap = _noop;
}

void _noop() {}
''');
  }

  Future<void> test_nonFunctionFieldIsIgnored() async {
    await assertNoDiagnostics(r'''
class A {
  final String handler = '';
}
''');
  }

  Future<void> test_functionNamedForWhatItComputes() async {
    await assertNoDiagnostics(r'''
class A {
  final String Function() builder = _build;
  final int Function(int, int) comparator = _compare;
}

String _build() => '';
int _compare(int a, int b) => 0;
''');
  }

  Future<void> test_overrideKeepsTheInheritedName() async {
    await assertNoDiagnostics(r'''
class Base {
  final void Function() onTap = _noop;
}

void _noop() {}
''');
  }

  Future<void> test_fieldFormalParameterIsNotReportedTwice() async {
    await assertDiagnostics(
      r'''
class A {
  A(this.tapCallback);

  final void Function() tapCallback;
}
''',
      [lint(58, 11)],
    );
  }

  Future<void> test_bareFrameworkNounIsTheThingItself() async {
    await assertNoDiagnostics(r'''
typedef Handler = void Function();

Handler middleware(Handler handler) => handler;

void configure(void Function() listener) {}
''');
  }

  Future<void> test_privateNameJudgedWithoutUnderscore() async {
    await assertNoDiagnostics(r'''
class A {
  final void Function() _onTap = _noop;
}

void _noop() {}
''');
  }

  Future<void> test_onWithoutAWordBoundary() async {
    await assertDiagnostics(
      r'''
class A {
  final void Function() onceHandler = _noop;
}

void _noop() {}
''',
      [lint(34, 11)],
    );
  }
}
