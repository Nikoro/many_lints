---
title: check_is_not_closed_after_async_gap
description: "Check isClosed before emitting state after an await"
sidebar:
  label: check_is_not_closed_after_async_gap
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Async Safety</span>

This rule flags an `emit(...)` call that happens after an `await` inside a `Bloc` or `Cubit`, without an intervening `if (isClosed) return;` guard.

## Why use this rule

A bloc can be closed while an asynchronous handler is suspended — the user navigates away mid-request, or the provider holding the bloc is disposed. When the awaited future finally completes, the handler resumes and emits into a bloc that no longer exists, which throws a `StateError`.

The failure is easy to miss: the throw happens inside a detached future, so it usually surfaces as an unhandled async error in the console rather than a crash you can trace. In tests it often does not appear at all.

Guarding with `if (isClosed) return;` after each await makes the handler exit cleanly instead.

This is the bloc counterpart to [`use_ref_and_state_synchronously`](/many_lints/docs/rules/async-safety/use-ref-and-state-synchronously/) and to Dart's own `use_build_context_synchronously`.

**See also:** [bloc: BlocBase.isClosed](https://pub.dev/documentation/bloc/latest/bloc/BlocBase/isClosed.html)

## Don't

```dart
class UserCubit extends Cubit<UserState> {
  UserCubit() : super(UserState.initial());

  Future<void> load() async {
    final user = await repository.fetchUser();
    // The cubit may have been closed while this was suspended
    emit(UserState.loaded(user));
  }
}
```

## Do

```dart
class UserCubit extends Cubit<UserState> {
  UserCubit() : super(UserState.initial());

  Future<void> load() async {
    final user = await repository.fetchUser();
    if (isClosed) return;
    emit(UserState.loaded(user));
  }
}
```

A guard resets the tracking, so a second `await` after it needs its own guard:

```dart
Future<void> loadTwice() async {
  final a = await repository.fetchA();
  if (isClosed) return;
  emit(UserState.loaded(a));

  final b = await repository.fetchB();
  if (isClosed) return;   // needed again
  emit(UserState.loaded(b));
}
```

## Known limitations

Both guard shapes are recognised: the early return `if (isClosed) return;` and the inverted wrapper `if (!isClosed) { emit(...); }`.

Statements are scanned in source order within one function body. An `emit` inside a nested closure is not reported, because that closure runs on its own schedule and its guards cannot be reasoned about from the enclosing scope. A guard hidden behind a helper method — `if (_shouldStop()) return;` — is also not recognised.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      check_is_not_closed_after_async_gap: false
```
