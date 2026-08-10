---
title: Assists
description: Refactorings many_lints offers from the editor's lightbulb menu, independent of any lint rule.
---

An **assist** is a refactoring you invoke deliberately, by putting the cursor somewhere and opening the lightbulb menu — <kbd>Ctrl</kbd> + <kbd>.</kbd> on Windows/Linux, <kbd>Cmd</kbd> + <kbd>.</kbd> on macOS in VS Code, or <kbd>Alt</kbd> + <kbd>Enter</kbd> in the JetBrains IDEs.

The difference from a [quick fix](/many_lints/docs/configuration/) matters in practice:

|  | Quick fix | Assist |
|--|-----------|--------|
| Triggered by | a reported diagnostic | cursor position |
| Needs a rule enabled | yes | **no** |
| Offers "apply all in file" | yes | no |

Because assists are not tied to a diagnostic, they work even with `preset: none` and no rules turned on at all. That independence is also why some transformations ship as an assist rather than as a fix: when the result needs a human eye — reviewing generated names, or choosing a direction the rules do not prefer — an "apply all" would be the wrong tool.

## Convert to collection-for

Put the cursor on a `.map()` call.

```dart
// Before
final doubled = numbers.map((e) => e * 2).toList();
final halved = numbers.map((e) => e / 2).toSet();

// After
final doubled = [for (final e in numbers) e * 2];
final halved = {for (final e in numbers) e / 2};
```

The trailing `.toList()` / `.toSet()` picks the literal that comes out; a bare `.map()` with no collector is left alone, since it is lazy and a collection literal is not.

## Convert to `Do` notation

Put the cursor on any `flatMap` in a nested chain. Related rule: [`prefer_do_notation`](/many_lints/docs/rules/fpdart/prefer-do-notation/).

```dart
// Before
Option<String> goShopping() => goToShoppingCenter().flatMap(
      (market) => market.buyBanana().flatMap(
            (banana) => market.buyApple().flatMap(
                  (apple) => Option.of('$banana, $apple'),
                ),
          ),
    );

// After
Option<String> goShopping() => Option.Do(($) {
      final market = $(goToShoppingCenter());
      final banana = $(market.buyBanana());
      final apple = $(market.buyApple());
      return '$banana, $apple';
    });
```

Each step's name comes from that callback's own parameter, and every generated name is offered as a **linked edit position** — accepting the assist drops the cursor on the first name with the rest reachable by <kbd>Tab</kbd>, so renaming is part of applying it rather than a follow-up chore.

The assist works from anywhere in the nest, not just the outermost call. An innermost `Option.of(x)` becomes a plain `return x`, because `Do` wraps the block's result itself.

This is an assist and not a fix on purpose: the generated names are only as good as the original parameter names, so "apply all" would be one keystroke away from a file full of `final a = ...`.

## Convert to `flatMap` chain

The inverse of the above. Put the cursor anywhere in a `Do` block.

```dart
// Before
Option<String> goShopping() => Option.Do(($) {
      final market = $(goToShoppingCenter());
      final banana = $(market.buyBanana());
      return '$banana';
    });

// After
Option<String> goShopping() => goToShoppingCenter().flatMap(
      (market) => market.buyBanana().flatMap(
        (banana) => Option.of('$banana'),
      ),
    );
```

A plain `return x` becomes `Type.of(x)` on the way out, since `Do` lifts its own result and a chain does not. In an async block, `await $(...)` loses the `await` — it belonged to the block rather than to the step.

**Only the straight-line shape converts**: a run of `final <name> = $(...)` bindings followed by a single `return`. A block that branches, loops, or extracts inside a larger expression is declined outright rather than half-translated, because `flatMap` is a fixed chain of continuations — turning an `if` into one would mean duplicating everything after it into both arms. A `Do` block doing that much is one where `Do` is genuinely the better notation.

## Convert to `TaskEither` / `TaskOption`

Put the cursor on a function that returns `Future<Either<L, R>>`, `Either<L, R>`, `Future<Option<T>>` or `Option<T>`. The lightbulb entry names the concrete target — "Convert to `TaskEither`" or "Convert to `TaskOption`".

Related rules: [`avoid_future_of_either`](/many_lints/docs/rules/fpdart/avoid-future-of-either/), [`avoid_future_of_option`](/many_lints/docs/rules/fpdart/avoid-future-of-option/).

**From `Future<Either<L, R>>`** — `TaskEither` is the same thing with the laziness and the combinators kept:

```dart
// Before
Future<Either<Failure, User>> getUser(String id) async {
  return right(await api.get(id));
}

// After
TaskEither<Failure, User> getUser(String id) => TaskEither(() async {
      return right(await api.get(id));
    });
```

**From `Either<L, R>`** — for when a synchronous pipeline has to grow an `await` in the middle. `Either` cannot host one; `TaskEither` can. The body is transplanted whole, so every `return left(...)` / `return right(...)` already in it keeps working:

```dart
// Before
Either<Failure, User> parse(String raw) {
  if (raw.isEmpty) return left(Failure.empty());
  return right(User.fromJson(raw));
}

// After — now an await can go anywhere inside
TaskEither<Failure, User> parse(String raw) => TaskEither(() async {
      if (raw.isEmpty) return left(Failure.empty());
      return right(User.fromJson(raw));
    });
```

`Option` works the same way, converting to `TaskOption`:

```dart
// Before
Option<User> find(String raw) {
  if (raw.isEmpty) return none();
  return some(User.fromJson(raw));
}

// After
TaskOption<User> find(String raw) => TaskOption(() async {
      if (raw.isEmpty) return none();
      return some(User.fromJson(raw));
    });
```

A body that already delegates to another `Future<Either>` becomes `TaskEither(() => src(id))`, without a redundant `async`.

:::caution[Call sites will not compile until you update them]
This changes a public signature: `await getUser(id)` has to become `await getUser(id).run()`, or better, the call has to be folded into the caller's own pipeline.

The assist deliberately leaves them alone. `.run()` is usually the *wrong* repair — it drops straight back out of the world the conversion just entered — and picking the right one means looking at each caller. A compile error pointing at every call site is more useful than a silent rewrite of files you cannot see.
:::

Functions with no written return type are declined, since the assist edits that type in place. So are generators — a single `TaskEither` cannot stand in for a stream of values.

## Expand `tryCatch` into `try`/`catch`

Put the cursor on a `tryCatch` constructor. Related rule: [`prefer_task_either_over_try_catch`](/many_lints/docs/rules/fpdart/prefer-task-either-over-try-catch/).

```dart
// Either.tryCatch
Either<Failure, User> parseUser(String json) {
  try {
    return right(User.fromJson(json));
  } catch (error, stackTrace) {
    return left(Failure.parse(error, stackTrace));
  }
}

// TaskEither.tryCatch — the try stays inside the lazy constructor, because
// hoisting it into the enclosing function would run the effect eagerly.
TaskEither<Failure, User> fetchUser(String id) => TaskEither(() async {
      try {
        return right(await api.getUser(id));
      } catch (error) {
        return left(Failure.from(error));
      }
    });

// Option.tryCatch — no onError, so there is no error to carry.
Option<User> tryParse(String json) {
  try {
    return some(User.fromJson(json));
  } catch (_) {
    return none();
  }
}
```

`tryCatch` remains the better form nearly always — it is shorter, cannot forget to wrap a branch, and composes. This assist is for the cases it cannot express: adding logging, retries, or handling per exception type, where a single `onError` callback is not enough.

Because `try` is a *statement*, the assist is offered only when the `tryCatch` makes up a whole function body (either `=> ...` or `{ return ...; }`). Mid-pipeline — `Either.tryCatch(...).flatMap(f)` — there is nowhere to put a statement, and the only expression-level equivalent is an immediately-invoked closure, which is worse than what it replaces. A tear-off `onError` such as `Failure.from` is declined too, since it has no parameter names or body to move into the `catch`.

A stack-trace parameter that `onError` declares but never reads is dropped from the generated clause: `onError` may carry an unused parameter, but `catch` may not, and keeping it would hand back code with a fresh `unused_catch_stack` warning the original could not have had.

## Convert null check to pattern

Put the cursor on an `if (x != null)` guard. Related rule: [`avoid_non_null_assertion`](/many_lints/docs/rules/code-quality/avoid-non-null-assertion/).

```dart
// Before
class Test {
  String? field;

  void method() {
    if (field != null) {
      field!.contains('other');
    }
  }
}

// After
class Test {
  String? field;

  void method() {
    if (field case final field_?) {
      field_.contains('other');
    }
  }
}
```

The point is **fields**. Dart promotes a local or a parameter after `x != null`, so a `!` there is already redundant and the SDK's own `unnecessary_null_checks` flags it. A field is never promoted — another method could reassign it between the check and the use — so every access inside the branch needs a `!` just to compile. Binding the value to a pattern variable makes it a fresh local, which *is* promotable, and the bangs go away.

The conversion preserves semantics exactly: the branch is entered on the same values as before, and an `else` still runs when the value is null. Bare reads of the field inside the branch are rewritten along with the bangs, so the branch never mixes the nullable original with the bound variable.

The generated name is offered as a linked edit, so <kbd>Tab</kbd> lands on it for renaming as part of applying the assist.

Two shapes are declined. `if (x == null)` guards its *else* branch, and the early-return form (`if (x == null) return;`) promotes the code *after* the `if` — neither is expressible as one `case` pattern. A method call as the checked expression is declined too, because the pattern re-evaluates its subject and a call could have side effects or return a different value the second time.

## Convert null check to destructuring pattern

Put the cursor on an `if (x != null)` guard whose branch asserts an inner field with `x!.field!`.

```dart
// Before
if (userData != null) {
  sendEvent(userData!.name!);
}

// After
if (userData case UserData(:final name?)) {
  sendEvent(name);
}
```

:::caution[This one changes behaviour]
The object pattern adds a second condition. When `userData != null` but `userData.name == null`, the original enters the branch and the rewritten form skips it.
:::

That is the whole point of the refactor, but it is why this is a separate assist from the one above rather than a smarter version of it. It is offered **only** when the branch contains `x!.field!`: asserting the field non-null is the author stating that a null there was never a case they meant to handle, so turning that assertion into a condition matches the intent already written down. Without the inner bang the assist declines, and the semantics-preserving conversion is offered instead.

Two more shapes are declined. When the branch asserts two *different* fields, there is no single name to destructure and picking one would be arbitrary — apply the assist again after the first conversion. A generic type is declined because `Box<String>(:final name?)` needs its arguments spelled out, and guessing them produces code that does not compile.

Neither of these ships as a quick fix. Both rewrite the whole `if`, while `avoid_non_null_assertion` reports on the `!` *inside* the branch — a fix that restructures the statement above the reported node is hard to predict. And "apply all in file" must not be able to narrow conditions across a codebase in one keystroke.
