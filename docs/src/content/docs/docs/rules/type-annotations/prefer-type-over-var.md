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

Flags variables declared with the `var` keyword instead of an explicit type annotation. Using `var` can make it harder to understand the type of a nickname, especially when the initializer is complex or the nullability is not obvious. This rule does not flag `final` or `const` declarations.

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

## Why use this rule

Explicit type annotations improve code readability and make the type system work for you. When a nickname is declared with `var`, readers must mentally resolve the initializer to understand the type, which slows down code review and increases the chance of subtle bugs around nullability or unexpected inference.

**See also:** [Effective Dart - Type annotations](https://dart.dev/effective-dart/design#types)

## Don't

```dart
var nickname = lookupNickname();
var anotherVar = 'string';
var number = 42;
var list = [1, 2, 3];

for (var i = 0; i < 10; i++) {
  print(i);
}

var cachedNickname = lookupNickname();
```

## Do

```dart
String? nickname = lookupNickname();
String anotherVar = 'string';
int number = 42;
List<int> list = [1, 2, 3];

for (int i = 0; i < 10; i++) {
  print(i);
}

String? cachedNickname = lookupNickname();

// final and const are allowed:
final inferred = lookupNickname();
const text = 'hello';
```

## Configuration

This rule is in **no preset**, so it is off unless you enable it — with
`preset: all`, or by name:

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
