import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_private_named_parameters.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferPrivateNamedParametersTest),
  );
}

@reflectiveTest
class PreferPrivateNamedParametersTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferPrivateNamedParameters();
    super.setUp();
  }

  // --- Positive cases (should trigger lint) ---

  Future<void> test_requiredNamedParameter() async {
    await assertDiagnostics(
      r'''
class Bird {
  final String _petName;
  Bird({required String petName}) : _petName = petName;
}
''',
      [lint(46, 23)],
    );
  }

  Future<void> test_optionalNamedParameterWithDefault() async {
    await assertDiagnostics(
      r'''
class Bird {
  final int _age;
  Bird({int age = 1}) : _age = age;
}
''',
      [lint(39, 11)],
    );
  }

  Future<void> test_untypedNamedParameter() async {
    await assertDiagnostics(
      r'''
class Bird {
  final dynamic _tag;
  Bird({tag}) : _tag = tag;
}
''',
      [lint(43, 3)],
    );
  }

  Future<void> test_multipleConvertibleParameters() async {
    await assertDiagnostics(
      r'''
class Bird {
  final String _name;
  final int _age;
  Bird({required String name, required int age})
    : _name = name,
      _age = age;
}
''',
      [lint(61, 20), lint(83, 16)],
    );
  }

  Future<void> test_constConstructor() async {
    await assertDiagnostics(
      r'''
class Bird {
  final String _petName;
  const Bird({required String petName}) : _petName = petName;
}
''',
      [lint(52, 23)],
    );
  }

  // --- Negative cases (should NOT trigger lint) ---

  Future<void> test_parameterUsedInBody() async {
    await assertNoDiagnostics(r'''
class Bird {
  final String _petName;
  Bird({required String petName}) : _petName = petName {
    print(petName);
  }
}
''');
  }

  Future<void> test_parameterUsedInAssert() async {
    await assertNoDiagnostics(r'''
class Bird {
  final String _petName;
  Bird({required String petName})
    : assert(petName != ''),
      _petName = petName;
}
''');
  }

  Future<void> test_parameterUsedInOtherInitializer() async {
    await assertNoDiagnostics(r'''
class Bird {
  final String _petName;
  final String _label;
  Bird({required String petName})
    : _petName = petName,
      _label = 'bird: $petName';
}
''');
  }

  Future<void> test_positionalParameter() async {
    await assertNoDiagnostics(r'''
class Bird {
  final String _petName;
  Bird(String petName) : _petName = petName;
}
''');
  }

  Future<void> test_publicField() async {
    await assertNoDiagnostics(r'''
class Bird {
  final String petName;
  Bird({required String name}) : petName = name;
}
''');
  }

  Future<void> test_nameMismatch() async {
    await assertNoDiagnostics(r'''
class Bird {
  final String _petName;
  Bird({required String name}) : _petName = name;
}
''');
  }

  Future<void> test_typeMismatch() async {
    await assertNoDiagnostics(r'''
class Bird {
  final num _age;
  Bird({required int age}) : _age = age;
}
''');
  }

  Future<void> test_alreadyPrivateNamedParameter() async {
    await assertNoDiagnostics(r'''
class Bird {
  final String _petName;
  Bird({required this._petName});
}
''');
  }

  Future<void> test_doubleUnderscoreField() async {
    await assertNoDiagnostics(r'''
class Bird {
  final String __petName;
  Bird({required String petName}) : __petName = petName;
}
''');
  }

  Future<void> test_expressionInitializer() async {
    await assertNoDiagnostics(r'''
class Bird {
  final String _petName;
  Bird({required String petName}) : _petName = '$petName!';
}
''');
  }

  // --- Edge cases ---

  Future<void> test_languageVersionBefore312() async {
    await assertNoDiagnostics(r'''
// @dart=3.11
class Bird {
  final String _petName;
  Bird({required String petName}) : _petName = petName;
}
''');
  }

  Future<void> test_functionTypedParameter() async {
    await assertNoDiagnostics(r'''
class Bird {
  final void Function() _onTap;
  Bird({required void onTap()}) : _onTap = onTap;
}
''');
  }
}
