---
title: avoid_build_context_in_providers
description: "Providers outlive widgets, so they should not receive a BuildContext."
sidebar:
  label: avoid_build_context_in_providers
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Riverpod State</span>

Flags a `BuildContext` parameter on a `@riverpod` provider — either a functional provider or a method of a `@riverpod` class.

## Why use this rule

Providers outlive the widgets that read them. A `BuildContext` held by a provider can easily refer to a widget that has already been unmounted, and using it then throws `dependOnInheritedWidgetOfExactType was called on a defunct widget` — or quietly reads stale inherited data. Passing the *value* you need instead keeps the provider independent of the widget tree, which is also what makes it testable without pumping a widget.

**See also:** [Riverpod families](https://riverpod.dev/docs/concepts2/family)

## Don't

```dart
@riverpod
int example(Ref ref, BuildContext context) => 0; // LINT

@riverpod
class Example extends _$Example {
  @override
  int build(BuildContext context) => 0; // LINT
}
```

## Do

```dart
// Pass the value read from the context, not the context itself.
@riverpod
int example(Ref ref, Locale locale) => 0;

// At the call site:
ref.watch(exampleProvider(Localizations.localeOf(context)));
```

Ordinary classes and functions are unaffected — only `@riverpod` declarations are checked:

```dart
int helper(BuildContext context) => 0; // no lint
```

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: all`. Add it to `preset: core` with
`avoid_build_context_in_providers: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_build_context_in_providers: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
