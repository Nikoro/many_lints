import 'package:many_lints/src/rule_config.dart';
import 'package:many_lints/src/rules/prefer_single_declaration_per_file.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferSingleDeclarationPerFileTest),
  );
}

@reflectiveTest
class PreferSingleDeclarationPerFileTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferSingleDeclarationPerFile();
    newPackage('bloc').addFile('lib/bloc.dart', r'''
class BlocBase<State> {}
class Bloc<Event, State> extends BlocBase<State> {}
class Cubit<State> extends BlocBase<State> {}
''');
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
class Notifier<State> {}
class AsyncNotifier<State> {}
''');
    newPackage('meta').addFile('lib/meta.dart', r'''
class _VisibleForTesting {
  const _VisibleForTesting();
}
const visibleForTesting = _VisibleForTesting();
''');
    super.setUp();
  }

  void configure(String options) {
    ConfigLoader.clearCache();
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n  ${rule.name}:\n$options',
    );
  }

  Future<void> test_singleClass_noLint() async {
    await assertNoDiagnostics(r'''
class A {}
''');
  }

  Future<void> test_twoClasses_lintsSecond() async {
    await assertDiagnostics(
      r'''
class A {}
class B {}
''',
      [lint(17, 1)],
    );
  }

  Future<void> test_threeClasses_lintsAllButFirst() async {
    await assertDiagnostics(
      r'''
class A {}
class B {}
class C {}
''',
      [lint(17, 1), lint(28, 1)],
    );
  }

  Future<void> test_mixedKinds_countTogetherByDefault() async {
    await assertDiagnostics(
      r'''
class A {}
enum B { one }
mixin C {}
''',
      [lint(16, 1), lint(32, 1)],
    );
  }

  Future<void> test_extensionType_counts() async {
    await assertDiagnostics(
      r'''
class A {}
extension type B(int it) {}
''',
      [lint(26, 1)],
    );
  }

  Future<void> test_namedExtension_counts() async {
    await assertDiagnostics(
      r'''
class A {}
extension B on int {}
''',
      [lint(21, 1)],
    );
  }

  Future<void> test_unnamedExtension_noLint() async {
    await assertNoDiagnostics(r'''
class A {}
extension on int {}
''');
  }

  Future<void> test_privateClass_ignoredByDefault() async {
    await assertNoDiagnostics(r'''
class A {}
class _B {}
''');
  }

  Future<void> test_functionsAndTypedefs_neverCount() async {
    await assertNoDiagnostics(r'''
class A {}
void f() {}
const x = 1;
typedef IntList = List<int>;
''');
  }

  Future<void> test_ignorePrivateFalse_countsPrivate() async {
    configure('    ignore_private: false\n');

    await assertDiagnostics(
      r'''
class A {}
class _B {}
''',
      [lint(17, 2)],
    );
  }

  Future<void> test_ignoreVisibleForTesting_skipsAnnotated() async {
    configure('''
    ignore_visible_for_testing: true
    kinds: [class]
''');

    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';

class A {}

@visibleForTesting
class B {}
''');
  }

  Future<void> test_visibleForTestingCountedByDefault() async {
    configure('    kinds: [class]\n');

    await assertDiagnostics(
      r'''
import 'package:meta/meta.dart';

class A {}

@visibleForTesting
class B {}
''',
      [lint(71, 1)],
    );
  }

  Future<void> test_kindsClassOnly_ignoresEnum() async {
    configure('    kinds: [class]\n');

    await assertNoDiagnostics(r'''
class A {}
enum B { one }
''');
  }

  Future<void> test_kindsClassOnly_stillCountsClasses() async {
    configure('    kinds: [class]\n');

    await assertDiagnostics(
      r'''
class A {}
enum B { one }
class C {}
''',
      [lint(32, 1)],
    );
  }

  Future<void> test_unknownKind_fallsBackToDefaults() async {
    configure('    kinds: [nonsense]\n');

    await assertDiagnostics(
      r'''
class A {}
class B {}
''',
      [lint(17, 1)],
    );
  }

  Future<void> test_typesNotifier_ignoresPlainClasses() async {
    configure('    types: [Notifier]\n');

    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class Helper {}
class Other {}
class CounterNotifier extends Notifier<int> {}
''');
  }

  Future<void> test_typesNotifier_lintsSecondNotifier() async {
    configure('    types: [Notifier]\n');

    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class CounterNotifier extends Notifier<int> {}
class OtherNotifier extends Notifier<int> {}
''',
      [lint(95, 13)],
    );
  }

  Future<void> test_typesMatchIndirectSubtypes() async {
    configure('    types: [BlocBase]\n');

    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';

class ABloc extends Bloc<int, int> {}
class BCubit extends Cubit<int> {}
''',
      [lint(78, 6)],
    );
  }

  Future<void> test_typesAcceptsBareScalar() async {
    configure('    types: Notifier\n');

    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class CounterNotifier extends Notifier<int> {}
class OtherNotifier extends Notifier<int> {}
''',
      [lint(95, 13)],
    );
  }

  Future<void> test_groups_independentBudgets_noLint() async {
    configure('''
    groups:
      - types: [Bloc, Cubit]
      - types: [Notifier]
''');

    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';
import 'package:riverpod/riverpod.dart';

class CounterBloc extends Bloc<int, int> {}
class CounterNotifier extends Notifier<int> {}
''');
  }

  Future<void> test_groups_secondOfSameGroupLints() async {
    configure('''
    groups:
      - types: [Bloc, Cubit]
      - types: [Notifier]
''');

    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';
import 'package:riverpod/riverpod.dart';

class CounterBloc extends Bloc<int, int> {}
class OtherBloc extends Bloc<int, int> {}
class CounterNotifier extends Notifier<int> {}
''',
      [lint(125, 9)],
    );
  }

  Future<void> test_groups_unmatchedDeclarationsIgnored() async {
    configure('''
    groups:
      - types: [Notifier]
''');

    await assertNoDiagnostics(r'''
class Helper {}
class Another {}
class Third {}
''');
  }

  Future<void>
  test_groups_perGroupMessageAppendsToItsOwnDiagnosticsOnly() async {
    configure('''
    groups:
      - types: [Bloc]
        message: 'One bloc per file.'
''');

    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';

class ABloc extends Bloc<int, int> {}
class BBloc extends Bloc<int, int> {}
''',
      [
        lint(
          78,
          5,
          messageContainsAll: [
            "Only one 'Bloc' declaration",
            'One bloc per file',
          ],
        ),
      ],
    );
  }

  Future<void> test_groups_inheritFlatDefaults() async {
    configure('''
    ignore_private: false
    groups:
      - types: [Notifier]
''');

    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class CounterNotifier extends Notifier<int> {}
class _PrivateNotifier extends Notifier<int> {}
''',
      [lint(95, 16)],
    );
  }

  Future<void> test_groups_overrideInheritedDefault() async {
    configure('''
    ignore_private: false
    groups:
      - types: [Notifier]
        ignore_private: true
''');

    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class CounterNotifier extends Notifier<int> {}
class _PrivateNotifier extends Notifier<int> {}
''');
  }

  Future<void> test_groups_overlappingCountedOnceByTheFirstGroup() async {
    configure('''
    groups:
      - types: [Bloc]
      - types: [BlocBase]
''');

    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';

class ABloc extends Bloc<int, int> {}
class BBloc extends Bloc<int, int> {}
''',
      [lint(78, 5)],
    );
  }

  Future<void> test_wrongTypedOption_fallsBackToDefault() async {
    configure('    ignore_private: "yes"\n');

    await assertDiagnostics(r'''
class A {}
class _B {}
''', []);
  }

  Future<void> test_allGroupsMalformed_keepsDefaultGroup() async {
    configure('''
    groups:
      - kinds: [nonsense]
''');

    await assertDiagnostics(
      r'''
class A {}
class B {}
''',
      [lint(17, 1)],
    );
  }
}
