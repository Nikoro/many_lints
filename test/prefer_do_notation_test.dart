import 'package:many_lints/src/rules/prefer_do_notation.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferDoNotationTest));
}

@reflectiveTest
class PreferDoNotationTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = PreferDoNotation();
    super.setUp();
  }

  Future<void> test_threeLevelNesting() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(Option<String> a, Option<String> b, Option<String> c) =>
    a.flatMap((x) => b.flatMap((y) => c.flatMap((z) => Option.of('$x$y$z'))));
''',
      [lint(118, 7)],
    );
  }

  Future<void> test_twoLevelNestingIsFineByDefault() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(Option<String> a, Option<String> b) =>
    a.flatMap((x) => b.flatMap((y) => Option.of('$x$y')));
''');
  }

  Future<void> test_chainedFlatMapIsFine() async {
    // Chaining is already flat; only nesting grows sideways.
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<int> g(String v) => Option.of(v.length);
Option<String> h(int v) => Option.of('$v');
Option<int> i(String v) => Option.of(v.length);

Option<int> f(Option<String> a) => a.flatMap(g).flatMap(h).flatMap(i);
''');
  }

  Future<void> test_doNotationIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(Option<String> a, Option<String> b, Option<String> c) =>
    Option.Do(($) {
      final x = $(a);
      final y = $(b);
      final z = $(c);
      return '$x$y$z';
    });
''');
  }

  Future<void> test_onlyOutermostReports() async {
    // A four-level nest is one shape with one fix, so exactly one diagnostic.
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(
  Option<String> a,
  Option<String> b,
  Option<String> c,
  Option<String> d,
) => a.flatMap(
  (w) => b.flatMap((x) => c.flatMap((y) => d.flatMap((z) => Option.of(w)))),
);
''',
      [lint(143, 7)],
    );
  }

  Future<void> test_maxDepthNarrows() async {
    newFile('$testPackageRootPath/many_lints.yaml', '''
rules:
  prefer_do_notation:
    max_flat_map_depth: 4
''');

    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(Option<String> a, Option<String> b, Option<String> c) =>
    a.flatMap((x) => b.flatMap((y) => c.flatMap((z) => Option.of('$x$y$z'))));
''');
  }

  Future<void> test_maxDepthWidens() async {
    newFile('$testPackageRootPath/many_lints.yaml', '''
rules:
  prefer_do_notation:
    max_flat_map_depth: 2
''');

    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(Option<String> a, Option<String> b) =>
    a.flatMap((x) => b.flatMap((y) => Option.of('$x$y')));
''',
      [lint(100, 7)],
    );
  }

  Future<void> test_legacyMaxFlatmapDepthAlias() async {
    newFile('$testPackageRootPath/many_lints.yaml', '''
rules:
  prefer_do_notation:
    max_flatmap_depth: 4
''');

    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(Option<String> a, Option<String> b, Option<String> c) =>
    a.flatMap((x) => b.flatMap((y) => c.flatMap((z) => Option.of('$x$y$z'))));
''');
  }

  Future<void> test_nonFpdartFlatMapIsFine() async {
    await assertNoDiagnostics(r'''
class Box<T> {
  Box<R> flatMap<R>(Box<R> Function(T) f) => throw '';
}

Box<int> f(Box<int> a, Box<int> b, Box<int> c) =>
    a.flatMap((x) => b.flatMap((y) => c.flatMap((z) => throw '')));
''');
  }
}
