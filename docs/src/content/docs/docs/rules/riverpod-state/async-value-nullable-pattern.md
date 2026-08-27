---
title: async_value_nullable_pattern
description: "Matching AsyncValue(:final value?) on a nullable value hides a legitimate null result."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: async_value_nullable_pattern
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Riverpod State</span>

Flags `AsyncValue(:final value?)` when the value type is nullable. The `?` pattern matches only when the value is non-null, which is not the same question as whether a value has loaded.

## Why use this rule

For an `AsyncValue<int?>`, a successfully loaded `null` is a real result. The `?` pattern rejects it, so that case silently falls through to the loading or error branch — the UI shows a spinner forever for data that actually arrived. `hasValue: true` asks the question you meant: *has this loaded?*

**See also:** [Riverpod - AsyncValue](https://pub.dev/documentation/riverpod/latest/riverpod/AsyncValue-class.html)

## Don't

A profile screen whose provider yields `User?` — `null` meaning "signed out",
which is a perfectly good loaded value. The `?` pattern rejects it, so a
signed-out user gets a spinner that never stops:

```dart
final currentUserProvider = FutureProvider<User?>((ref) => auth.currentUser());

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return switch (user) {
      AsyncValue(:final value?) => Text(value.name), // LINT
      AsyncValue(:final error?) => Text('$error'),
      _ => const CircularProgressIndicator(),
    };
  }
}
```

## Do

Ask the question you meant — *has this loaded?* — and handle the null yourself:

```dart
final currentUserProvider = FutureProvider<User?>((ref) => auth.currentUser());

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return switch (user) {
      AsyncValue(:final value, hasValue: true) =>
        Text(value?.name ?? 'Signed out'),
      AsyncValue(:final error?) => Text('$error'),
      _ => const CircularProgressIndicator(),
    };
  }
}
```

## Known limitations

The rule stays silent where the `?` pattern is already precise.

A non-nullable value type — `null` can then only mean "not loaded", which is
exactly what `?` asks:

```dart
void fn(AsyncValue<int> asyncValue) {
  switch (asyncValue) {
    case AsyncValue(:final value?):
      print(value);
    default:
      break;
  }
}
```

Matching `AsyncData` rather than `AsyncValue` — `AsyncData.hasValue` is always
true, so the null check is doing real work:

```dart
void onData(AsyncValue<int?> asyncValue) {
  switch (asyncValue) {
    case AsyncData(:final value?):
      print(value);
    default:
      break;
  }
}
```

## Configuration

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: opinionated`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  async_value_nullable_pattern: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_build_context_in_providers`](/many_lints/docs/rules/riverpod-state/avoid-build-context-in-providers/) — Providers outlive widgets, so they should not receive a BuildContext.
- [`avoid_ref_inside_state_dispose`](/many_lints/docs/rules/riverpod-state/avoid-ref-inside-state-dispose/) — Avoid accessing ref inside the dispose method of a ConsumerState.
- [`avoid_ref_read_inside_build`](/many_lints/docs/rules/riverpod-state/avoid-ref-read-inside-build/) — Subscribe in build; do not read once.
- [`avoid_ref_watch_outside_build`](/many_lints/docs/rules/riverpod-state/avoid-ref-watch-outside-build/) — Subscribe only in build; read once everywhere else.
