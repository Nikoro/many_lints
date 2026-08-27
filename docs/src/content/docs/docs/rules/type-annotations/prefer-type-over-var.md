---
title: prefer_type_over_var
description: "Prefer an explicit type annotation over 'var'."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_type_over_var
---

<span class="rule-badge rule-badge--version">v0.3.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Type Annotations</span>

Flags a variable declared with `var` instead of an explicit type annotation. `final` and `const` declarations are never reported — only the `var` keyword is.

:::caution[Conflicts with an SDK rule you probably have enabled]
The SDK rule [`omit_local_variable_types`](https://dart.dev/tools/linter-rules/omit_local_variable_types) mandates the **opposite** of this rule — it asks you to remove type annotations that inference can supply. It ships in `package:lints/recommended.yaml`, so most projects have it on by default.

With both enabled you get contradictory diagnostics on every `var`. Pick one philosophy and disable the other:

```yaml
# analysis_options.yaml — if you keep prefer_type_over_var
linter:
  rules:
    omit_local_variable_types: false
```

If you want explicit types but find this rule too strict, the SDK offers softer alternatives: [`specify_nonobvious_local_variable_types`](https://dart.dev/tools/linter-rules/specify_nonobvious_local_variable_types) flags only declarations whose type is not obvious from the initializer, while [`always_specify_types`](https://dart.dev/tools/linter-rules/always_specify_types) is the strict equivalent. Note that all three SDK rules are mutually incompatible with `omit_local_variable_types`.
:::

## Don't

The type of a `var` is whatever the initializer happened to return, and the
reader has to go and look — which matters most where it is easiest to get
wrong, around nullability:

```dart
String? findNickname(int userId) => null;

void greet(int userId) {
  var nickname = findNickname(userId);
  // `nickname` is String?, not String — nothing on this line says so.
  print(nickname.length);
}
```

Top-level and for-loop declarations are reported too:

```dart
var retryCount = 3;
var pendingIds = <int>[];

void retryAll() {
  for (var i = 0; i < retryCount; i++) {
    print(pendingIds[i]);
  }
}
```

## Do

Write the type. The nullability is now visible at the declaration:

```dart
String? findNickname(int userId) => null;

void greet(int userId) {
  String? nickname = findNickname(userId);
  print(nickname?.length);
}

int retryCount = 3;
List<int> pendingIds = <int>[];

void retryAll() {
  for (int i = 0; i < retryCount; i++) {
    print(pendingIds[i]);
  }
}
```

### `final` and `const` are never reported

The rule keys on the `var` keyword alone, so an immutable declaration with an
inferred type passes as it is:

```dart
final resolved = findNickname(7);
const greeting = 'hello';

// `final` with a type is also fine, of course.
final String? explicit = findNickname(7);
```

**See also:** [Effective Dart - Type annotations](https://dart.dev/effective-dart/design#types)

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_type_over_var: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_type_over_var: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_explicit_function_type`](/many_lints/docs/rules/type-annotations/prefer-explicit-function-type/) — Prefer explicit function type annotations over the bare 'Function' type.
- [`prefer_explicit_type_arguments`](/many_lints/docs/rules/type-annotations/prefer-explicit-type-arguments/) — Pin the type arguments of the APIs where inference surprises.
- [`prefer_async_callback`](/many_lints/docs/rules/type-annotations/prefer-async-callback/) — Use 'AsyncCallback' instead of 'Future&lt;void&gt; Function()'.
- [`prefer_equatable_mixin`](/many_lints/docs/rules/type-annotations/prefer-equatable-mixin/) — Prefer using EquatableMixin instead of extending Equatable.
