import 'package:test/test.dart';

import '../fix_harness.dart';
import '../fpdart_stub.dart';

void main() {
  late FixHarness harness;

  setUp(() async {
    harness = FixHarness();
    await harness.setUp();
  });

  tearDown(() async {
    await harness.tearDown();
  });

  group('prefer_unit_over_void', () {
    Future<String> applyFix(String content) => harness.applyFix(
      content,
      'prefer_unit_over_void',
      multiFilePackages: {'fpdart': fpdartStubFiles},
    );

    test('replaces a void type argument with Unit', () async {
      final fixed = await applyFix(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, void> save() => throw '';
''');

      expect(fixed, contains('TaskEither<String, Unit> save()'));
      expect(fixed, isNot(contains('TaskEither<String, void>')));
    });

    test('rewrites only the void argument, not the whole type', () async {
      final fixed = await applyFix(r'''
import 'package:fpdart/fpdart.dart';

Either<String, void> compute() => throw '';
''');

      // The left type argument must survive untouched — a fix that rewrote
      // the whole NamedType would silently drop it.
      expect(fixed, contains('Either<String, Unit> compute()'));
    });

    test('adds the fpdart import when it is missing', () async {
      // The file names the type through a library that does not re-export
      // `Unit`, so the fix has to bring the import in itself.
      final fixed = await applyFix(r'''
import 'package:fpdart/src/task_either.dart';

TaskEither<String, void> save() => throw '';
''');

      expect(fixed, contains("import 'package:fpdart/fpdart.dart'"));
      expect(fixed, contains('TaskEither<String, Unit> save()'));
    });

    test('does not duplicate an fpdart import that is already there', () async {
      final fixed = await applyFix(r'''
import 'package:fpdart/fpdart.dart';

Option<void> f() => throw '';
''');

      expect(fixed, contains('Option<Unit> f()'));
      expect(
        "import 'package:fpdart/fpdart.dart'".allMatches(fixed),
        hasLength(1),
        reason: 'the fix must not add an import the file already has',
      );
    });
  });

  group('prefer_from_nullable', () {
    Future<String> applyFix(String content) => harness.applyFix(
      content,
      'prefer_from_nullable',
      multiFilePackages: {'fpdart': fpdartStubFiles},
    );

    test('collapses a != null conditional into fromNullable', () async {
      final fixed = await applyFix(r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(String? name) =>
    name != null ? Option.of(name) : Option<String>.none();
''');

      expect(fixed, contains('Option.fromNullable(name)'));
      // The conditional is gone; `String?` in the signature still has a `?`,
      // so assert on the branches rather than on the character.
      expect(fixed, isNot(contains('Option.of(')));
      expect(fixed, isNot(contains('.none()')));
    });

    test('collapses the inverted == null spelling too', () async {
      final fixed = await applyFix(r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(String? name) =>
    name == null ? Option<String>.none() : Option.of(name);
''');

      expect(fixed, contains('Option.fromNullable(name)'));
    });

    test('keeps the tested expression, not just a bare name', () async {
      // The value under test is a property access, so a fix that assumed a
      // simple identifier would drop the receiver.
      final fixed = await applyFix(r'''
import 'package:fpdart/fpdart.dart';

class User {
  String? name;
}

Option<String> f(User user) =>
    user.name != null ? Option.of(user.name) : Option<String>.none();
''');

      expect(fixed, contains('Option.fromNullable(user.name)'));
    });
  });

  group('prefer_string_parse_extensions', () {
    Future<String> applyFix(String content) => harness.applyFix(
      content,
      'prefer_string_parse_extensions',
      multiFilePackages: {'fpdart': fpdartStubFiles},
    );

    test('rewrites a wrapped int.tryParse to toIntOption', () async {
      final fixed = await applyFix(r'''
import 'package:fpdart/fpdart.dart';

Option<int> f(String input) => Option.fromNullable(int.tryParse(input));
''');

      expect(fixed, contains('input.toIntOption'));
      expect(fixed, isNot(contains('tryParse')));
    });

    test('rewrites double.tryParse to toDoubleOption', () async {
      final fixed = await applyFix(r'''
import 'package:fpdart/fpdart.dart';

Option<double> f(String input) =>
    Option.fromNullable(double.tryParse(input));
''');

      expect(fixed, contains('input.toDoubleOption'));
    });

    test('parenthesises a receiver that binds looser than "."', () async {
      // Without parentheses `a ?? b` would become `a ?? b.toIntOption`, which
      // parses as a different expression entirely.
      final fixed = await applyFix(r'''
import 'package:fpdart/fpdart.dart';

Option<int> f(String? a, String b) =>
    Option.fromNullable(int.tryParse(a ?? b));
''');

      expect(fixed, contains('(a ?? b).toIntOption'));
    });

    test('keeps a property-access receiver intact', () async {
      final fixed = await applyFix(r'''
import 'package:fpdart/fpdart.dart';

class Form {
  String age = '';
}

Option<int> f(Form form) => Option.fromNullable(int.tryParse(form.age));
''');

      expect(fixed, contains('form.age.toIntOption'));
    });
  });

  group('prefer_safe_collection_access', () {
    Future<String> applyFix(String content) => harness.applyFix(
      content,
      'prefer_safe_collection_access',
      multiFilePackages: {'fpdart': fpdartStubFiles},
    );

    test('swaps first for head', () async {
      final fixed = await applyFix(r'''
import 'package:fpdart/fpdart.dart';

Option<int> f(List<int> values) => Option.of(values.first);
''');

      expect(fixed, contains('values.head'));
      expect(fixed, isNot(contains('values.first')));
    });

    test('swaps last for lastOption', () async {
      final fixed = await applyFix(r'''
import 'package:fpdart/fpdart.dart';

Option<int> f(List<int> values) => Option.of(values.last);
''');

      expect(fixed, contains('values.lastOption'));
    });

    test('replaces only the accessor, keeping the receiver', () async {
      final fixed = await applyFix(r'''
import 'package:fpdart/fpdart.dart';

class Team {
  List<int> scores = [];
}

Option<int> f(Team team) => Option.of(team.scores.first);
''');

      expect(fixed, contains('team.scores.head'));
    });
  });

  group('prefer_from_predicate', () {
    Future<String> applyFix(String content) => harness.applyFix(
      content,
      'prefer_from_predicate',
      multiFilePackages: {'fpdart': fpdartStubFiles},
    );

    test('substitutes the value for the lambda parameter', () async {
      final fixed = await applyFix(r'''
import 'package:fpdart/fpdart.dart';

Option<int> f(int age) => age > 18 ? Option.of(age) : Option<int>.none();
''');

      expect(fixed, contains('Option.fromPredicate(age, (a) => a > 18)'));
    });

    test('substitutes every occurrence in the condition', () async {
      final fixed = await applyFix(r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(String name) =>
    name.isNotEmpty ? Option.of(name) : Option<String>.none();
''');

      expect(
        fixed,
        contains('Option.fromPredicate(name, (n) => n.isNotEmpty)'),
      );
    });

    test('picks a parameter name that does not shadow one in scope', () async {
      // `a` is already bound in the condition, so the naive first initial
      // would shadow it and change what the predicate tests.
      final fixed = await applyFix(r'''
import 'package:fpdart/fpdart.dart';

Option<int> f(int amount, int a) =>
    amount > a ? Option.of(amount) : Option<int>.none();
''');

      expect(fixed, contains('Option.fromPredicate(amount, (a2) => a2 > a)'));
    });
  });
}
