import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/provider_parameters.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(ProviderParametersTest));
}

@reflectiveTest
class ProviderParametersTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = ProviderParameters();

    // Mirrors the real package: a family is a callable object, so invoking it
    // is a FunctionExpressionInvocation on a `Family`-typed target — which is
    // what distinguishes a family call from a provider declaration.
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
class ProviderBase<T> {}

class Family<T, Arg> {
  ProviderBase<T> call(Arg arg) => throw UnimplementedError();
}

class Provider<T> extends ProviderBase<T> {
  static Family<T, Arg> family<T, Arg>(T Function(Object ref, Arg arg) create) =>
      throw UnimplementedError();
}
''');

    super.setUp();
  }

  // --- Positive cases: should trigger lint ---

  Future<void> test_nonConstListArgument() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

final myProvider = Provider.family<int, List<int>>((ref, arg) => 0);

void fn() {
  myProvider([1, 2, 3]);
}
''',
      [lint(137, 9)],
    );
  }

  Future<void> test_closureArgument() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

final myProvider = Provider.family<int, Object>((ref, arg) => 0);

void fn() {
  myProvider(() => 42);
}
''',
      [lint(134, 8)],
    );
  }

  Future<void> test_instanceWithoutEqualsArgument() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class Foo {}

final myProvider = Provider.family<int, Foo>((ref, arg) => 0);

void fn() {
  myProvider(Foo());
}
''',
      [lint(145, 5)],
    );
  }

  // --- Negative cases: should not trigger lint ---

  Future<void> test_constListArgument() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

final myProvider = Provider.family<int, List<int>>((ref, arg) => 0);

void fn() {
  myProvider(const [1, 2, 3]);
}
''');
  }

  Future<void> test_primitiveArgument() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

final myProvider = Provider.family<int, int>((ref, arg) => 0);

void fn() {
  myProvider(42);
}
''');
  }

  Future<void> test_constInstanceArgument() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class Foo {
  const Foo();
}

final myProvider = Provider.family<int, Foo>((ref, arg) => 0);

void fn() {
  myProvider(const Foo());
}
''');
  }

  Future<void> test_instanceOverridingEqualsArgument() async {
    // A class with a real `==` compares equal across rebuilds.
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class Foo {
  Foo(this.id);
  final int id;

  @override
  bool operator ==(Object other) => other is Foo && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

final myProvider = Provider.family<int, Foo>((ref, arg) => 0);

void fn() {
  myProvider(Foo(1));
}
''');
  }

  Future<void> test_providerDeclarationNotFlagged() async {
    // `Provider.family(...)` returns a provider type too, but its argument is
    // the create callback — not a family parameter.
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

final myProvider = Provider.family<int, List<int>>((ref, arg) => arg.length);
final otherProvider = Provider.family<int, Object>((ref, arg) => 0);
''');
  }

  Future<void> test_nonProviderInvocationNotFlagged() async {
    await assertNoDiagnostics(r'''
void takes(Object value) {}

void fn() {
  takes([1, 2, 3]);
  takes(() => 42);
}
''');
  }
}
