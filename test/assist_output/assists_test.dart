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

      expect(result.source, r'''
import 'package:fpdart/fpdart.dart';

Option<String> a() => Option.of('a');
Option<String> b() => Option.of('b');
Option<String> c() => Option.of('c');

Option<String> f() => Option.Do(($) {
  final first = $(a());
  final second = $(b());
  final third = $(c());
  return '$first$second$third';
});
''');
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

      expect(result.source, r'''
import 'package:fpdart/fpdart.dart';

Option<String> a() => Option.of('a');
Option<String> b() => Option.of('b');
Option<String> c() => Option.of('c');

Option<String> f() => Option.Do(($) {
  final first = $(a());
  final second = $(b());
  return $(c());
});
''');
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

      expect(result.source, r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> a() => TaskEither.of(1);
TaskEither<String, int> b() => TaskEither.of(2);

TaskEither<String, int> f() => TaskEither.Do(($) {
  final first = $(a());
  final second = $(b());
  return first + second;
});
''');
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

      expect(result.source, r'''
import 'package:fpdart/fpdart.dart';

class Market {
  Option<String> buyBanana() => Option.of('banana');
  Option<String> buyApple() => Option.of('apple');
}

Option<Market> goToShoppingCenter() => Option.of(Market());
Option<Market> goToLocalMarket() => Option.of(Market());

String goShopping() => Option.Do(($) {
  final market = $(goToShoppingCenter().alt(goToLocalMarket));
  final banana = $(market.buyBanana());
  final apple = $(market.buyApple());
  return 'Shopping: $banana, $apple';
})
    .getOrElse(() => 'nothing bought');
''');
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

      expect(result.source, r'''
import 'package:fpdart/fpdart.dart';

Option<String> a() => Option.of('a');
Option<String> b() => Option.of('b');

Option<String> f() => Option.Do(($) {
  final first = $(a());
  final second = $(b());
  return '$first$second';
});
''');
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

      // `Do` lifts its own result, so a plain `return x` has to be re-wrapped
      // to keep the chain well-typed.
      expect(source, r'''
import 'package:fpdart/fpdart.dart';

Option<String> a() => Option.of('a');
Option<String> b() => Option.of('b');
Option<String> c() => Option.of('c');

Option<String> f() => a().flatMap(
  (first) => b().flatMap(
    (second) => c().flatMap(
      (third) => Option.of('$first$second$third'),
    ),
  ),
);
''');
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

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

class Market {
  Option<String> buyBanana() => Option.of('banana');
  Option<String> buyApple() => Option.of('apple');
}

Option<Market> goToShoppingCenter() => Option.of(Market());

Option<String> goShopping() => goToShoppingCenter().flatMap(
  (market) => market.buyBanana().flatMap(
    (banana) => market.buyApple().flatMap(
      (apple) => Option.of('Shopping: $banana, $apple'),
    ),
  ),
);
''');
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

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> a() => TaskEither.of(1);
TaskEither<String, int> b() => TaskEither.of(2);

TaskEither<String, int> f() => a().flatMap(
  (first) => b().flatMap(
    (second) => TaskEither.of(first + second),
  ),
);
''');
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

      // The last step stays `c()`, not `Option.of(c())` — the returned
      // pipeline is already wrapped.
      expect(source, r'''
import 'package:fpdart/fpdart.dart';

Option<String> a() => Option.of('a');
Option<String> b() => Option.of('b');
Option<String> c() => Option.of('c');

Option<String> f() => a().flatMap(
  (first) => b().flatMap(
    (second) => c(),
  ),
);
''');
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

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

Option<String> a() => Option.of('a');
Option<String> b() => Option.of('b');

Option<String> f() => a().flatMap(
  (first) => b().flatMap(
    (second) => Option.of('$first$second'),
  ),
);
''');
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

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

class Failure {
  Failure.parse(Object e, StackTrace s);
}

class User {
  static User fromJson(String json) => User();
}

Either<Failure, User> parseUser(String json) {
  try {
    return right(User.fromJson(json));
  } catch (error, stackTrace) {
    return left(Failure.parse(error, stackTrace));
  }
}
''');
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

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

class Failure {
  Failure.from(Object e);
}

class User {}

Future<User> getUser(String id) async => User();

TaskEither<Failure, User> fetchUser(String id) => TaskEither(() async {
      try {
        return right(await getUser(id));
      } catch (error) {
        return left(Failure.from(error));
      }
    });
''');
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

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

class Failure {
  Failure.from(Object e);
}

class User {}

Future<User> getUser(String id) async => User();

TaskEither<Failure, User> fetchUser(String id) => TaskEither(() async {
      try {
        return right(await getUser(id));
      } catch (error) {
        return left(Failure.from(error));
      }
    });
''');
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

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

class User {
  static User fromJson(String json) => User();
}

Option<User> tryParse(String json) {
  try {
    return some(User.fromJson(json));
  } catch (_) {
    return none();
  }
}
''');
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

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

class Failure {
  Failure.from(Object e);
}

class User {
  static User fromJson(String json) => User();
}

Either<Failure, User> parseUser(String json) {
  try {
    return right(User.fromJson(json));
  } catch (error) {
    return left(Failure.from(error));
  }
}
''');
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

    test('declines a cursor inside an unrelated nested closure', () async {
      // `_enclosingTryCatch` walks up from the cursor. Without a function
      // boundary it sails out of this inner closure and offers to expand the
      // enclosing `tryCatch`, which is not the code the cursor is in.
      final ids = await idsAt(r'''
import 'package:fpdart/fpdart.dart';

class Failure {
  Failure.from(Object e);
}

int apply(int Function() f) => f();

Either<Failure, int> outer() => Either.tryCatch(
      () => apply(() => 4^2),
      (error, stackTrace) => Failure.from(error),
    );
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
      expect(source, r'''
import 'package:fpdart/fpdart.dart';

class Failure {}
class User {}

Future<User> api(String id) async => User();

TaskEither<Failure, User> getUser(String id) => TaskEither(() async {
      return right(await api(id));
    });
''');
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

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

class Failure {}
class User {}

TaskEither<Failure, User> parse(String raw) => TaskEither(() async {
      if (raw.isEmpty) return left(Failure());
      return right(User());
    });
''');
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

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

class Failure {}
class User {}

TaskEither<Failure, User> parse(String raw) => TaskEither(() async {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return left(Failure());
      return right(User());
    });
''');
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

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

class Failure {}
class User {}

Future<Either<Failure, User>> src(String id) async => right(User());

TaskEither<Failure, User> delegate(String id) => TaskEither(() => src(id));
''');
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

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

class Failure {}
class User {}

class Repository {
  TaskEither<Failure, User> getUser(String id) => TaskEither(() async {
          return right(User());
        });
}
''');
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

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

typedef AppFailure = String;

class User {}

TaskEither<AppFailure, User> parse(String raw) => TaskEither(() async => right(User()));
''');
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

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

class User {}

Future<Option<User>> src(String id) async => none();

TaskOption<User> find(String id) => TaskOption(() => src(id));
''');
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

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

class User {}

TaskOption<User> find(String raw) => TaskOption(() async {
      if (raw.isEmpty) return none();
      return some(User());
    });
''');
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

      expect(source, r'''
class Test {
  String? field;

  void method() {
    if (field case final field_?) {
      field_.contains('other');
    }
  }
}
''');
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

      expect(source, r'''
class Test {
  String? field;

  void method() {
    if (field case final field_?) {
      print(field_);
      print(field_.length);
    }
  }
}
''');
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

      expect(source, r'''
class Test {
  String? field;

  void method() {
    if (field case final field_?) {
      print(field_);
    } else {
      print('none');
    }
  }
}
''');
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

      expect(source, r'''
class UserData {
  String? name;
}

void sendEvent(String value) {}

class Holder {
  UserData? userData;

  void method() {
    if (userData case UserData(:final name?)) {
      sendEvent(name);
    }
  }
}
''');
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

      expect(result.source, r'''
void f(List<int> values) {
  final doubled = [for (final e in values) e * 2];
}
''');
    });
  });

  group('convert_flat_map_to_and_then', () {
    Future<String> applyAssist(String content) async {
      final result = await harness.applyAssist(
        content,
        'many_lints.assist.convertFlatMapToAndThen',
        multiFilePackages: {'fpdart': fpdartStubFiles},
      );
      return result.source;
    }

    test('emits a tear-off for a bare no-argument call', () async {
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

class Repo {
  TaskEither<String, int> logout() => throw '';
}

TaskEither<String, int> f(TaskEither<String, String> p, Repo repo) =>
    p.flat^Map((_) => repo.logout());
''');

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

class Repo {
  TaskEither<String, int> logout() => throw '';
}

TaskEither<String, int> f(TaskEither<String, String> p, Repo repo) =>
    p.andThen(repo.logout);
''');
    });

    test('keeps a thunk when the call takes arguments', () async {
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> seed(int count) => throw '';

TaskEither<String, int> f(TaskEither<String, String> p) =>
    p.flat^Map((_) => seed(3));
''');

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> seed(int count) => throw '';

TaskEither<String, int> f(TaskEither<String, String> p) =>
    p.andThen(() => seed(3));
''');
    });

    test('is not offered when the parameter is used', () async {
      final offered = await harness.assistIds(
        r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> parse(String raw) => throw '';

TaskEither<String, int> f(TaskEither<String, String> p) =>
    p.flat^Map((value) => parse(value));
''',
        multiFilePackages: {'fpdart': fpdartStubFiles},
      );

      expect(
        offered,
        isNot(contains('many_lints.assist.convertFlatMapToAndThen')),
      );
    });
  });

  group('convert_flat_map_to_map', () {
    Future<String> applyAssist(String content) async {
      final result = await harness.applyAssist(
        content,
        'many_lints.assist.convertFlatMapToMap',
        multiFilePackages: {'fpdart': fpdartStubFiles},
      );
      return result.source;
    }

    test('emits a tear-off when the body is exactly f(v)', () async {
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

int transform(String value) => throw '';

TaskEither<String, int> f(TaskEither<String, String> p) =>
    p.flat^Map((v) => TaskEither.right(transform(v)));
''');

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

int transform(String value) => throw '';

TaskEither<String, int> f(TaskEither<String, String> p) =>
    p.map(transform);
''');
    });

    test('is not offered when the body branches', () async {
      final offered = await harness.assistIds(
        r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, String> f(TaskEither<String, String> p) =>
    p.flat^Map((v) => v.isEmpty ? TaskEither.left('e') : TaskEither.right(v));
''',
        multiFilePackages: {'fpdart': fpdartStubFiles},
      );

      expect(offered, isNot(contains('many_lints.assist.convertFlatMapToMap')));
    });
  });

  group('convert_flat_map_to_filter_or_else', () {
    Future<String> applyAssist(String content) async {
      final result = await harness.applyAssist(
        content,
        'many_lints.assist.convertFlatMapToFilterOrElse',
        multiFilePackages: {'fpdart': fpdartStubFiles},
      );
      return result.source;
    }

    test('converts the keep-on-true form', () async {
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, String> f(TaskEither<String, String> p) =>
    p.flat^Map((v) => v.isEmpty ? TaskEither.right(v) : TaskEither.left('bad'));
''');

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, String> f(TaskEither<String, String> p) =>
    p.filterOrElse((v) => v.isEmpty, (v) => 'bad');
''');
    });

    test('negates the predicate when the branches are reversed', () async {
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, String> f(TaskEither<String, String> p) =>
    p.flat^Map((v) => v.isEmpty ? TaskEither.left('bad') : TaskEither.right(v));
''');

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, String> f(TaskEither<String, String> p) =>
    p.filterOrElse((v) => !v.isEmpty, (v) => 'bad');
''');
    });
  });

  group('convert_flat_map_to_chain_first', () {
    test('converts the run-effect-keep-value shape', () async {
      final result = await harness.applyAssist(
        r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> audit(String user) => throw '';

TaskEither<String, String> f(TaskEither<String, String> p) =>
    p.flat^Map((user) => audit(user).map((_) => user));
''',
        'many_lints.assist.convertFlatMapToChainFirst',
        multiFilePackages: {'fpdart': fpdartStubFiles},
      );

      expect(result.source, r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> audit(String user) => throw '';

TaskEither<String, String> f(TaskEither<String, String> p) =>
    p.chainFirst(audit);
''');
    });

    test('is not offered when the inner map returns something else', () async {
      final offered = await harness.assistIds(
        r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> audit(String user) => throw '';

TaskEither<String, int> f(TaskEither<String, String> p) =>
    p.flat^Map((user) => audit(user).map((count) => count));
''',
        multiFilePackages: {'fpdart': fpdartStubFiles},
      );

      expect(
        offered,
        isNot(contains('many_lints.assist.convertFlatMapToChainFirst')),
      );
    });
  });

  group('convert_reduce_to_sequence_list', () {
    test('converts a sequential reduce to sequenceListSeq', () async {
      final result = await harness.applyAssist(
        r'''
import 'package:fpdart/fpdart.dart';

extension <E> on Iterable<E> {
  E reduce(E Function(E value, E element) combine) => throw '';
}

TaskEither<String, int> f(List<TaskEither<String, int>> tasks) =>
    tasks.reduce^((acc, t) => acc.flatMap((_) => t));
''',
        'many_lints.assist.convertReduceToSequenceList',
        multiFilePackages: {'fpdart': fpdartStubFiles},
      );

      // Always the Seq variant: the reduce is inherently sequential.
      expect(result.source, r'''
import 'package:fpdart/fpdart.dart';

extension <E> on Iterable<E> {
  E reduce(E Function(E value, E element) combine) => throw '';
}

TaskEither<String, int> f(List<TaskEither<String, int>> tasks) =>
    TaskEither.sequenceListSeq(tasks);
''');
      expect(result.source, isNot(contains('sequenceList(')));
    });

    test('is not offered for an unrelated reduce', () async {
      final offered = await harness.assistIds(r'''
extension <E> on Iterable<E> {
  E reduce(E Function(E value, E element) combine) => throw '';
}

int f(List<int> values) => values.re^duce((a, b) => a + b);
''');

      expect(
        offered,
        isNot(contains('many_lints.assist.convertReduceToSequenceList')),
      );
    });
  });

  group('expand_to_flat_map', () {
    Future<String> applyAssist(String content) async {
      final result = await harness.applyAssist(
        content,
        'many_lints.assist.expandToFlatMap',
        multiFilePackages: {'fpdart': fpdartStubFiles},
      );
      return result.source;
    }

    test('expands a tear-off andThen', () async {
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> logout() => throw UnimplementedError();

TaskEither<String, int> f(TaskEither<String, String> p) =>
    p.and^Then(logout);
''');

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> logout() => throw UnimplementedError();

TaskEither<String, int> f(TaskEither<String, String> p) =>
    p.flatMap((_) => logout());
''');
    });

    test('inlines the body of a thunk andThen', () async {
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> seed(int count) => throw UnimplementedError();

TaskEither<String, int> f(TaskEither<String, String> p) =>
    p.and^Then(() => seed(3));
''');

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> seed(int count) => throw UnimplementedError();

TaskEither<String, int> f(TaskEither<String, String> p) =>
    p.flatMap((_) => seed(3));
''');
    });

    test('expands map with the wrapper the call returns', () async {
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

int transform(String raw) => throw UnimplementedError();

TaskEither<String, int> f(TaskEither<String, String> p) =>
    p.m^ap(transform);
''');

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

int transform(String raw) => throw UnimplementedError();

TaskEither<String, int> f(TaskEither<String, String> p) =>
    p.flatMap((value) => TaskEither.of(transform(value)));
''');
    });

    test('keeps the closure parameter name when expanding map', () async {
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

int transform(String raw) => throw UnimplementedError();

TaskEither<String, int> f(TaskEither<String, String> p) =>
    p.m^ap((raw) => transform(raw));
''');

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

int transform(String raw) => throw UnimplementedError();

TaskEither<String, int> f(TaskEither<String, String> p) =>
    p.flatMap((raw) => TaskEither.of(transform(raw)));
''');
    });

    test('expands filterOrElse into the ternary it is defined as', () async {
      final source = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, String> f(TaskEither<String, String> p) =>
    p.filterOr^Else((v) => v.isEmpty, (v) => 'bad');
''');

      expect(source, r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, String> f(TaskEither<String, String> p) =>
    p.flatMap((v) => v.isEmpty ? TaskEither.of(v) : TaskEither.left('bad'));
''');
    });

    test('round-trips the andThen narrowing assist', () async {
      // The two directions must agree, the way the Do-notation pair does.
      final narrowed = await harness.applyAssist(
        r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> logout() => throw UnimplementedError();

TaskEither<String, int> f(TaskEither<String, String> p) =>
    p.flat^Map((_) => logout());
''',
        'many_lints.assist.convertFlatMapToAndThen',
        multiFilePackages: {'fpdart': fpdartStubFiles},
      );

      expect(narrowed.source, contains('p.andThen(logout)'));

      final expanded = await applyAssist(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> logout() => throw UnimplementedError();

TaskEither<String, int> f(TaskEither<String, String> p) =>
    p.and^Then(logout);
''');

      expect(expanded, contains('p.flatMap((_) => logout())'));
    });

    test('is not offered for chainFirst', () async {
      // Expanding it honestly needs the orElse, and the short form silently
      // drops the failure-swallowing. Neither output is worth offering.
      final offered = await harness.assistIds(
        r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> audit(String user) => throw UnimplementedError();

TaskEither<String, String> f(TaskEither<String, String> p) =>
    p.chainFir^st(audit);
''',
        multiFilePackages: {'fpdart': fpdartStubFiles},
      );

      expect(offered, isNot(contains('many_lints.assist.expandToFlatMap')));
    });

    test('is not offered for a non-fpdart map', () async {
      final offered = await harness.assistIds(r'''
List<int> f(List<String> values) => values.m^ap(int.parse).toList();
''');

      expect(offered, isNot(contains('many_lints.assist.expandToFlatMap')));
    });
  });
}
