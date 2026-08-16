import 'package:many_lints/src/rule_config.dart';
import 'package:many_lints/src/rules/prefer_explicit_type_arguments.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferExplicitTypeArgumentsTest);
    defineReflectiveTests(PreferExplicitTypeArgumentsUnconfiguredTest);
  });
}

@reflectiveTest
class PreferExplicitTypeArgumentsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferExplicitTypeArguments();
    super.setUp();
    ConfigLoader.clearCache();
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n'
          '  prefer_explicit_type_arguments:\n'
          '    methods: [showDialog]\n',
    );
  }

  Future<void> test_configuredCallWithoutTypeArguments() async {
    await assertDiagnostics(
      r'''
Future<T?> showDialog<T>(Object builder) async => null;

Future<void> open() async {
  await showDialog((_) => 1);
}
''',
      [lint(93, 10)],
    );
  }

  Future<void> test_explicitTypeArgumentsAreFine() async {
    await assertNoDiagnostics(r'''
Future<T?> showDialog<T>(Object builder) async => null;

Future<void> open() async {
  await showDialog<bool>((_) => 1);
}
''');
  }

  // A method that is not in the configured list is left alone, which is the
  // asymmetric half proving the list is what drives the rule.
  Future<void> test_unlistedMethodIsSilent() async {
    await assertNoDiagnostics(r'''
Future<T?> showSheet<T>(Object builder) async => null;

Future<void> open() async {
  await showSheet((_) => 1);
}
''');
  }

  // A non-generic call cannot take type arguments, so asking for them would be
  // asking for a compile error.
  Future<void> test_nonGenericCallIsSilent() async {
    await assertNoDiagnostics(r'''
Future<void> showDialog(Object builder) async {}

Future<void> open() async {
  await showDialog((_) => 1);
}
''');
  }
}

/// The control: with no `methods` configured the rule must report nothing.
@reflectiveTest
class PreferExplicitTypeArgumentsUnconfiguredTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferExplicitTypeArguments();
    super.setUp();
  }

  Future<void> test_silentWithoutConfiguration() async {
    await assertNoDiagnostics(r'''
Future<T?> showDialog<T>(Object builder) async => null;

Future<void> open() async {
  await showDialog((_) => 1);
}
''');
  }
}
