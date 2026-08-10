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

  group('convert_flat_map_to_do_notation', () {
    Future<({String source, List<dynamic> linkedGroups})> applyAssist(
      String content,
    ) async {
      final result = await harness.applyAssist(
        content,
        'many_lints.assist.convertFlatMapToDoNotation',
        multiFilePackages: {'fpdart': fpdartStubFiles},
      );
      return (source: result.source, linkedGroups: result.linkedGroups);
    }

    test('flattens a nest into a Do block', () async {
      final result = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

Option<String> a() => Option.of('a');
Option<String> b() => Option.of('b');
Option<String> c() => Option.of('c');

Option<String> f() => a().flat^Map(
      (first) => b().flatMap(
            (second) => c().flatMap(
                  (third) => Option.of('$first$second$third'),
                ),
          ),
    );
''');

      expect(result.source, contains(r'Option.Do(($) {'));
      expect(result.source, contains(r"final first = $(a());"));
      expect(result.source, contains(r"final second = $(b());"));
      expect(result.source, contains(r"final third = $(c());"));
      // The innermost `Option.of(x)` unwraps to a plain return, since `Do`
      // wraps the block's result itself.
      expect(result.source, contains(r"return '$first$second$third';"));
      expect(result.source, isNot(contains('flatMap')));
    });

    test('offers every generated name as a linked edit position', () async {
      final result = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

Option<String> a() => Option.of('a');
Option<String> b() => Option.of('b');

Option<String> f() => a().flat^Map(
      (first) => b().flatMap((second) => Option.of('$first$second')),
    );
''');

      // One group per extracted step, so Tab walks the names.
      expect(result.linkedGroups, hasLength(2));
    });

    test('keeps a non-lifting last step as an extraction', () async {
      // The innermost callback returns a pipeline rather than `Option.of(x)`,
      // so it stays a `$(...)` extraction instead of being unwrapped.
      final result = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

Option<String> a() => Option.of('a');
Option<String> b() => Option.of('b');
Option<String> c() => Option.of('c');

Option<String> f() => a().flat^Map(
      (first) => b().flatMap((second) => c()),
    );
''');

      expect(result.source, contains(r'return $(c());'));
    });

    test('works on TaskEither too', () async {
      final result = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> a() => TaskEither.of(1);
TaskEither<String, int> b() => TaskEither.of(2);

TaskEither<String, int> f() => a().flat^Map(
      (first) => b().flatMap((second) => TaskEither.of(first + second)),
    );
''');

      expect(result.source, contains(r'TaskEither.Do(($) {'));
      expect(result.source, contains(r'return first + second;'));
    });

    test('handles the README shopping example end to end', () async {
      // The chain has work on both sides of the nest: `.alt(...)` folded into
      // the first step's source, and `.getOrElse(...)` left untouched after
      // the block.
      final result = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

class Market {
  Option<String> buyBanana() => Option.of('banana');
  Option<String> buyApple() => Option.of('apple');
}

Option<Market> goToShoppingCenter() => Option.of(Market());
Option<Market> goToLocalMarket() => Option.of(Market());

String goShopping() => goToShoppingCenter()
    .alt(goToLocalMarket)
    .flat^Map(
      (market) => market.buyBanana().flatMap(
            (banana) => market.buyApple().flatMap(
                  (apple) => Option.of('Shopping: $banana, $apple'),
                ),
          ),
    )
    .getOrElse(() => 'nothing bought');
''');

      expect(
        result.source,
        contains(
          r"final market = $(goToShoppingCenter().alt(goToLocalMarket));",
        ),
      );
      expect(result.source, contains(r"final banana = $(market.buyBanana());"));
      expect(result.source, contains(r"final apple = $(market.buyApple());"));
      expect(result.source, contains(r"return 'Shopping: $banana, $apple';"));
      // The tail of the chain survives the rewrite.
      expect(result.source, contains(".getOrElse(() => 'nothing bought')"));
      // Generated lines are indented from the line's own leading whitespace,
      // not from everything preceding the call on that line.
      expect(result.source, isNot(contains('String goShopping() =>   final')));
    });

    test('is offered from anywhere in the nest', () async {
      // The cursor sits on the *inner* flatMap, but the assist rewrites the
      // whole nest from its outermost call.
      final result = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

Option<String> a() => Option.of('a');
Option<String> b() => Option.of('b');

Option<String> f() => a().flatMap(
      (first) => b().flat^Map((second) => Option.of('$first$second')),
    );
''');

      expect(result.source, contains(r'Option.Do(($) {'));
      expect(result.source, contains(r"final first = $(a());"));
    });
  });

  group('convert_do_notation_to_flat_map', () {
    const assistId = 'many_lints.assist.convertDoNotationToFlatMap';

    Future<String> applyAssist(String content) async {
      final result = await harness.applyAssist(
        content,
        assistId,
        multiFilePackages: {'fpdart': fpdartStubFiles},
      );
      return result.source;
    }

    test('unfolds a block into a nested flatMap chain', () async {
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

Option<String> a() => Option.of('a');
Option<String> b() => Option.of('b');
Option<String> c() => Option.of('c');

Option<String> f() => Option.Do(($) {
      final first = $(a());
      final second = $(b());
      final third = $(c^());
      return '$first$second$third';
    });
''');

      expect(source, contains('a().flatMap('));
      expect(source, contains('(first) => b().flatMap('));
      expect(source, contains('(second) => c().flatMap('));
      // `Do` lifts its own result, so a plain `return x` has to be re-wrapped
      // to keep the chain well-typed.
      expect(source, contains(r"(third) => Option.of('$first$second$third')"));
      expect(source, isNot(contains('Option.Do')));
    });

    test('round-trips the forward assist output', () async {
      // What convert_flat_map_to_do_notation emits must convert straight back.
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

class Market {
  Option<String> buyBanana() => Option.of('banana');
  Option<String> buyApple() => Option.of('apple');
}

Option<Market> goToShoppingCenter() => Option.of(Market());

Option<String> goShopping() => Option.Do(($) {
      final market = $(goToShoppingCent^er());
      final banana = $(market.buyBanana());
      final apple = $(market.buyApple());
      return 'Shopping: $banana, $apple';
    });
''');

      expect(source, contains('goToShoppingCenter().flatMap('));
      expect(source, contains('(market) => market.buyBanana().flatMap('));
      expect(source, contains('(banana) => market.buyApple().flatMap('));
      expect(
        source,
        contains(r"(apple) => Option.of('Shopping: $banana, $apple')"),
      );
    });

    test('strips the await of an async block', () async {
      // `TaskEither.Do` extracts with `await $(...)`; the await belongs to the
      // block, not to the step, so it must not survive into the chain.
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> a() => TaskEither.of(1);
TaskEither<String, int> b() => TaskEither.of(2);

TaskEither<String, int> f() => TaskEither.Do(($) async {
      final first = await $(a^());
      final second = await $(b());
      return first + second;
    });
''');

      expect(source, contains('a().flatMap('));
      expect(source, contains('(first) => b().flatMap('));
      expect(source, contains('(second) => TaskEither.of(first + second)'));
      expect(source, isNot(contains('await')));
    });

    test('keeps a returned extraction unwrapped', () async {
      // `return $(c())` is already a pipeline, so it becomes the chain's tail
      // directly rather than being wrapped in another `Option.of`.
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

Option<String> a() => Option.of('a');
Option<String> b() => Option.of('b');
Option<String> c() => Option.of('c');

Option<String> f() => Option.Do(($) {
      final first = $(a^());
      final second = $(b());
      return $(c());
    });
''');

      expect(source, contains('(second) => c(),'));
      // Not `Option.of(c())` — the returned pipeline is already wrapped.
      expect(source, isNot(contains('Option.of(c())')));
    });

    test('is offered from anywhere in the block', () async {
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

Option<String> a() => Option.of('a');
Option<String> b() => Option.of('b');

Option<String> f() => Option.Do(($) {
      final first = $(a());
      final second = $(b());
      return '$first$secon^d';
    });
''');

      expect(source, contains('a().flatMap('));
    });

    test('declines a block that is not straight-line bindings', () async {
      // An `if` in the body has no direct `flatMap` equivalent — the
      // continuation would have to be duplicated into both arms — so the
      // assist must not be offered at all.
      final ids = await harness.assistIds(
        r'''
import 'package:fpdart/fpdart.dart';

Option<String> a() => Option.of('a');

Option<String> f() => Option.Do(($) {
      final first = $(a^());
      if (first.isEmpty) {
        return 'empty';
      }
      return first;
    });
''',
        multiFilePackages: {'fpdart': fpdartStubFiles},
      );

      expect(ids, isNot(contains(assistId)));
    });

    test('declines when a binding mixes extraction with computation', () async {
      // `$(a()).length` is not a bare step, so unfolding it would change what
      // the binding means.
      final ids = await harness.assistIds(
        r'''
import 'package:fpdart/fpdart.dart';

Option<String> a() => Option.of('a');

Option<int> f() => Option.Do(($) {
      final length = $(a^()).length;
      return length;
    });
''',
        multiFilePackages: {'fpdart': fpdartStubFiles},
      );

      expect(ids, isNot(contains(assistId)));
    });

    test(
      'declines when the result mixes extraction with computation',
      () async {
        // `$(b()) + first` extracts inside a larger expression; the tail of a
        // flatMap chain has nowhere to put that extra step.
        final ids = await harness.assistIds(
          r'''
import 'package:fpdart/fpdart.dart';

Option<int> a() => Option.of(1);
Option<int> b() => Option.of(2);

Option<int> f() => Option.Do(($) {
      final first = $(a^());
      return $(b()) + first;
    });
''',
          multiFilePackages: {'fpdart': fpdartStubFiles},
        );

        expect(ids, isNot(contains(assistId)));
      },
    );
  });

  group('convert_try_catch_constructor_to_try_statement', () {
    const assistId =
        'many_lints.assist.convertTryCatchConstructorToTryStatement';

    Future<String> applyAssist(String content) async {
      final result = await harness.applyAssist(
        content,
        assistId,
        multiFilePackages: {'fpdart': fpdartStubFiles},
      );
      return result.source;
    }

    Future<List<String>> idsAt(String content) => harness.assistIds(
      content,
      multiFilePackages: {'fpdart': fpdartStubFiles},
    );

    test('expands Either.tryCatch into a try statement', () async {
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

class Failure {
  Failure.parse(Object e, StackTrace s);
}

class User {
  static User fromJson(String json) => User();
}

Either<Failure, User> parseUser(String json) => Either.tryC^atch(
      () => User.fromJson(json),
      (error, stackTrace) => Failure.parse(error, stackTrace),
    );
''');

      expect(source, contains('  try {'));
      expect(source, contains('return right(User.fromJson(json));'));
      expect(source, contains('} catch (error, stackTrace) {'));
      expect(
        source,
        contains('return left(Failure.parse(error, stackTrace));'),
      );
      expect(source, isNot(contains('tryCatch')));
    });

    test('expands TaskEither.tryCatch inside a lazy TaskEither', () async {
      // Hoisting the `try` into the enclosing function would run the effect
      // eagerly, so it has to stay inside `TaskEither(() async { ... })`.
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

class Failure {
  Failure.from(Object e);
}

class User {}

Future<User> getUser(String id) async => User();

TaskEither<Failure, User> fetchUser(String id) => TaskEither.tryC^atch(
      () => getUser(id),
      (error, stackTrace) => Failure.from(error),
    );
''');

      expect(source, contains('TaskEither(() async {'));
      expect(source, contains('return right(await getUser(id));'));
      expect(source, contains('return left(Failure.from(error));'));
    });

    test('drops an unused stack trace from the catch clause', () async {
      // `onError` may declare a stack trace it never reads; `catch` may not —
      // that earns an `unused_catch_stack` warning, so the expanded code would
      // arrive with a fresh lint the original could not have had.
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

class Failure {
  Failure.from(Object e);
}

class User {}

Future<User> getUser(String id) async => User();

TaskEither<Failure, User> fetchUser(String id) => TaskEither.tryC^atch(
      () => getUser(id),
      (error, stackTrace) => Failure.from(error),
    );
''');

      expect(source, contains('} catch (error) {'));
      expect(source, isNot(contains('catch (error, stackTrace)')));
    });

    test('expands Option.tryCatch with a parameterless catch', () async {
      // `Option.tryCatch` has no `onError` — there is no error to carry — so
      // the clause takes nothing and the failure branch is `none()`.
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

class User {
  static User fromJson(String json) => User();
}

Option<User> tryParse(String json) =>
    Option.tryC^atch(() => User.fromJson(json));
''');

      expect(source, contains('return some(User.fromJson(json));'));
      expect(source, contains('} catch (_) {'));
      expect(source, contains('return none();'));
    });

    test('expands a block body that only returns the tryCatch', () async {
      // `{ return Either.tryCatch(...); }` is the same shape written the long
      // way, so it converts to the same block rather than being declined.
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

class Failure {
  Failure.from(Object e);
}

class User {
  static User fromJson(String json) => User();
}

Either<Failure, User> parseUser(String json) {
  return Either.tryC^atch(
    () => User.fromJson(json),
    (error, stackTrace) => Failure.from(error),
  );
}
''');

      expect(source, contains('return right(User.fromJson(json));'));
      expect(source, contains('} catch (error) {'));
      // Not a block nested in the block it replaced.
      expect(source, isNot(contains('{\n  {')));
    });

    test('declines mid-pipeline, where a statement has nowhere to go', () async {
      // `try` is a statement; a `tryCatch` feeding `.flatMap` is an expression
      // in the middle of a chain, and the only expression-level equivalent is
      // an immediately-invoked closure.
      final ids = await idsAt(r'''
import 'package:fpdart/fpdart.dart';

class Failure {
  Failure.from(Object e);
}

class User {}

User parse(String json) => User();
Either<Failure, User> validate(User user) => Either.of(user);

Either<Failure, User> parseUser(String json) => Either.tryC^atch(
      () => parse(json),
      (error, stackTrace) => Failure.from(error),
    ).flatMap(validate);
''');

      expect(ids, isNot(contains(assistId)));
    });

    test('declines a tear-off onError, which has no body to move', () async {
      final ids = await idsAt(r'''
import 'package:fpdart/fpdart.dart';

class Failure {
  Failure.from(Object e);
  static Failure of(Object e, StackTrace s) => Failure.from(e);
}

class User {}

User parse(String json) => User();

Either<Failure, User> parseUser(String json) =>
    Either.tryC^atch(() => parse(json), Failure.of);
''');

      expect(ids, isNot(contains(assistId)));
    });

    test('declines a tryCatch that is not fpdart', () async {
      final ids = await idsAt(r'''
class Other<T> {
  factory Other.tryCatch(T Function() run, T Function(Object, StackTrace) f) =>
      throw '';
}

Other<int> f() => Other.tryC^atch(() => 1, (error, stackTrace) => 0);
''');

      expect(ids, isNot(contains(assistId)));
    });
  });

  group('convert_to_lazy_fpdart_type', () {
    const assistId = 'many_lints.assist.convertToLazyFpdartType';

    Future<String> applyAssist(String content) async {
      final result = await harness.applyAssist(
        content,
        assistId,
        multiFilePackages: {'fpdart': fpdartStubFiles},
      );
      return result.source;
    }

    Future<List<String>> idsAt(String content) => harness.assistIds(
      content,
      multiFilePackages: {'fpdart': fpdartStubFiles},
    );

    test('converts a Future<Either> method', () async {
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

class Failure {}
class User {}

Future<User> api(String id) async => User();

Future<Either<Failure, User>> get^User(String id) async {
  return right(await api(id));
}
''');

      expect(
        source,
        contains(
          'TaskEither<Failure, User> getUser(String id) => TaskEither(() async {',
        ),
      );
      expect(source, contains('      return right(await api(id));'));
      expect(source, contains('    });'));
      expect(source, isNot(contains('Future<Either')));
    });

    test('converts an Either method so it can host an await', () async {
      // The whole point of this direction: `Either` cannot contain an
      // `await`, `TaskEither` can. Every existing `return left(...)` stays
      // valid because the block is transplanted rather than rewritten.
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

class Failure {}
class User {}

Either<Failure, User> par^se(String raw) {
  if (raw.isEmpty) return left(Failure());
  return right(User());
}
''');

      expect(
        source,
        contains(
          'TaskEither<Failure, User> parse(String raw) => TaskEither(() async {',
        ),
      );
      expect(
        source,
        contains('      if (raw.isEmpty) return left(Failure());'),
      );
      expect(source, contains('      return right(User());'));
    });

    test('keeps a multi-statement block on separate lines', () async {
      // `toSource()` discards line breaks, so a block has to be copied from
      // the original text; collapsing a body onto one line would be a
      // silently mangled refactor rather than a failed one.
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

class Failure {}
class User {}

Either<Failure, User> par^se(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return left(Failure());
  return right(User());
}
''');

      expect(source, contains('      final trimmed = raw.trim();\n'));
      expect(
        source,
        contains('      if (trimmed.isEmpty) return left(Failure());\n'),
      );
    });

    test('does not add a redundant async to a delegating body', () async {
      // `=> src(id)` already evaluates to a `Future<Either>`, so it is
      // already the thunk `TaskEither` wants.
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

class Failure {}
class User {}

Future<Either<Failure, User>> src(String id) async => right(User());

Future<Either<Failure, User>> deleg^ate(String id) => src(id);
''');

      expect(
        source,
        contains(
          'TaskEither<Failure, User> delegate(String id) => '
          'TaskEither(() => src(id));',
        ),
      );
      expect(source, isNot(contains('() async => src(id)')));
    });

    test('converts a method on a class', () async {
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

class Failure {}
class User {}

class Repository {
  Future<Either<Failure, User>> get^User(String id) async {
    return right(User());
  }
}
''');

      expect(
        source,
        contains('TaskEither<Failure, User> getUser(String id) =>'),
      );
    });

    test('keeps the written type arguments verbatim', () async {
      // Reading the resolved type would expand aliases into names that may
      // not be in scope where the replacement lands.
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

typedef AppFailure = String;

class User {}

Either<AppFailure, User> par^se(String raw) => right(User());
''');

      expect(source, contains('TaskEither<AppFailure, User> parse'));
    });

    test('declines a plain Future that holds no Either', () async {
      final ids = await idsAt(r'''
class User {}

Future<User> get^User(String id) async => User();
''');

      expect(ids, isNot(contains(assistId)));
    });

    test('declines a function with no written return type', () async {
      // The replacement edits the return type in place; there is nothing to
      // edit when it was never written.
      final ids = await idsAt(r'''
import 'package:fpdart/fpdart.dart';

class Failure {}
class User {}

par^se(String raw) => Either<Failure, User>.of(User());
''');

      expect(ids, isNot(contains(assistId)));
    });

    test('converts a Future<Option> method to TaskOption', () async {
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

class User {}

Future<Option<User>> fin^d(String id) async => none();
''');

      // The body was written `async => none()`, so the `async` is what makes
      // it a `Future<Option>` and has to survive into the thunk.
      expect(
        source,
        contains(
          'TaskOption<User> find(String id) => TaskOption(() async => none());',
        ),
      );
    });

    test('drops a redundant async for a delegating Option body', () async {
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

class User {}

Future<Option<User>> src(String id) async => none();

Future<Option<User>> fin^d(String id) => src(id);
''');

      expect(
        source,
        contains(
          'TaskOption<User> find(String id) => TaskOption(() => src(id));',
        ),
      );
    });

    test('converts an Option method to TaskOption', () async {
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

class User {}

Option<User> fin^d(String raw) {
  if (raw.isEmpty) return none();
  return some(User());
}
''');

      expect(
        source,
        contains('TaskOption<User> find(String raw) => TaskOption(() async {'),
      );
      expect(source, contains('      if (raw.isEmpty) return none();'));
    });

    test('declines a generator, which yields many values', () async {
      final ids = await idsAt(r'''
import 'package:fpdart/fpdart.dart';

class Failure {}
class User {}

Stream<Either<Failure, User>> ea^ch() async* {
  yield right(User());
}
''');

      expect(ids, isNot(contains(assistId)));
    });
  });

  group('convert_null_check_to_pattern', () {
    const assistId = 'many_lints.assist.convertNullCheckToPattern';

    Future<String> applyAssist(String content) async {
      final result = await harness.applyAssist(content, assistId);
      return result.source;
    }

    Future<List<String>> idsAt(String content) => harness.assistIds(content);

    test('binds a checked field so the bang disappears', () async {
      final source = await applyAssist(r'''
class Test {
  String? field;

  void method() {
    if (fi^eld != null) {
      field!.contains('other');
    }
  }
}
''');

      expect(source, contains('if (field case final field_?)'));
      expect(source, contains("field_.contains('other')"));
      expect(source, isNot(contains('!')));
    });

    test('rewrites plain reads alongside the bangs', () async {
      // Leaving a bare `field` behind would mix the nullable original with the
      // promoted pattern variable, which reads as two different values.
      final source = await applyAssist(r'''
class Test {
  String? field;

  void method() {
    if (fi^eld != null) {
      print(field);
      print(field!.length);
    }
  }
}
''');

      expect(source, contains('print(field_)'));
      expect(source, contains('print(field_.length)'));
    });

    test('preserves the else branch', () async {
      final source = await applyAssist(r'''
class Test {
  String? field;

  void method() {
    if (fi^eld != null) {
      print(field!);
    } else {
      print('none');
    }
  }
}
''');

      expect(source, contains('if (field case final field_?)'));
      expect(source, contains("} else {"));
      expect(source, contains("print('none')"));
    });

    test('offers the bound name as a linked edit position', () async {
      final result = await harness.applyAssist(r'''
class Test {
  String? field;

  void method() {
    if (fi^eld != null) {
      field!.contains('other');
    }
  }
}
''', assistId);

      expect(result.linkedGroups, hasLength(1));
    });

    // `x == null` guards the *else*, and the early-return form promotes the
    // code after the `if` — neither is one `case` pattern.
    test('declines an == null check', () async {
      final ids = await idsAt(r'''
class Test {
  String? field;

  void method() {
    if (fi^eld == null) {
      return;
    }
    field!.contains('other');
  }
}
''');

      expect(ids, isNot(contains(assistId)));
    });

    // Re-evaluating a call as the pattern subject could run side effects a
    // second time, or return a different value.
    test('declines a method call as the checked expression', () async {
      final ids = await idsAt(r'''
class Test {
  String? compute() => null;

  void method() {
    if (comp^ute() != null) {
      compute()!.contains('other');
    }
  }
}
''');

      expect(ids, isNot(contains(assistId)));
    });

    test('declines an if that already uses a pattern', () async {
      final ids = await idsAt(r'''
class Test {
  String? field;

  void method() {
    if (fi^eld case final value?) {
      value.contains('other');
    }
  }
}
''');

      expect(ids, isNot(contains(assistId)));
    });
  });

  group('inline_null_check_into_pattern', () {
    const assistId = 'many_lints.assist.inlineNullCheckIntoPattern';

    Future<String> applyAssist(String content) async {
      final result = await harness.applyAssist(content, assistId);
      return result.source;
    }

    Future<List<String>> idsAt(String content) => harness.assistIds(content);

    test('destructures the field the branch asserts non-null', () async {
      final source = await applyAssist(r'''
class UserData {
  String? name;
}

void sendEvent(String value) {}

class Holder {
  UserData? userData;

  void method() {
    if (user^Data != null) {
      sendEvent(userData!.name!);
    }
  }
}
''');

      expect(source, contains('if (userData case UserData(:final name?))'));
      expect(source, contains('sendEvent(name)'));
      expect(source, isNot(contains('!')));
    });

    test('offers the destructured name as a linked edit position', () async {
      final result = await harness.applyAssist(r'''
class UserData {
  String? name;
}

void sendEvent(String value) {}

class Holder {
  UserData? userData;

  void method() {
    if (user^Data != null) {
      sendEvent(userData!.name!);
    }
  }
}
''', assistId);

      expect(result.linkedGroups, hasLength(1));
    });

    // Without the inner bang the branch does not assert the field is non-null,
    // so narrowing the condition would change behaviour the author never asked
    // for. That case belongs to the semantics-preserving assist instead.
    test('declines when the inner field is not asserted', () async {
      final ids = await idsAt(r'''
class UserData {
  String? name;
}

class Holder {
  UserData? userData;

  void method() {
    if (user^Data != null) {
      print(userData!.name);
    }
  }
}
''');

      expect(ids, isNot(contains(assistId)));
      // The safe conversion is still available here.
      expect(ids, contains('many_lints.assist.convertNullCheckToPattern'));
    });

    test('declines when two different fields are asserted', () async {
      final ids = await idsAt(r'''
class UserData {
  String? name;
  String? email;
}

class Holder {
  UserData? userData;

  void method() {
    if (user^Data != null) {
      print(userData!.name!);
      print(userData!.email!);
    }
  }
}
''');

      expect(ids, isNot(contains(assistId)));
    });

    // `UserData<String>(:final name?)` would need the arguments spelled out,
    // and guessing them produces code that does not compile.
    test('declines a generic type', () async {
      final ids = await idsAt(r'''
class Box<T> {
  String? name;
}

class Holder {
  Box<String>? box;

  void method() {
    if (b^ox != null) {
      print(box!.name!);
    }
  }
}
''');

      expect(ids, isNot(contains(assistId)));
    });
  });

  group('convert_iterable_map_to_collection_for', () {
    // The assist's own transformation logic is covered thoroughly in
    // `test/convert_iterable_map_to_collection_for_test.dart`, which drives
    // `CorrectionProducerContext` directly. That route constructs the assist
    // itself, so it passes whether or not the assist is registered with the
    // plugin — a missing `registerAssist` would be invisible to all ten of
    // those tests.
    //
    // This group closes that gap: one end-to-end pass through a real
    // `PluginServer`, proving the assist is actually offered to an editor.
    test('is offered through the plugin server', () async {
      final result = await harness.applyAssist(r'''
void f(List<int> values) {
  final doubled = values.m^ap((e) => e * 2).toList();
}
''', 'many_lints.assist.convertIterableMapToCollectionFor');

      expect(result.source, contains('[for(final e in values) e * 2]'));
      expect(result.source, isNot(contains('.map(')));
    });
  });
}
