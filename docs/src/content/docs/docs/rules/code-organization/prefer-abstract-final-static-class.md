---
title: prefer_abstract_final_static_class
description: "Classes with only static members should be declared as abstract final."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_abstract_final_static_class
---

<span class="rule-badge rule-badge--version">v0.3.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Code Organization</span>

Flags classes that contain only static members but are not declared as `abstract final`. Without these modifiers, a static-only class can be accidentally instantiated or subclassed, which is almost never the intended use.

:::caution[Contradicts an SDK rule]
The SDK rule [`avoid_classes_with_only_static_members`](https://dart.dev/tools/linter-rules/avoid_classes_with_only_static_members) gives the **opposite** advice: it says not to create such a class at all, and to use top-level functions and constants instead — Dart has real top-level declarations, unlike Java.

This rule instead assumes you want to keep the class as a namespace and only asks you to seal it. The two are mutually exclusive, so enable at most one:

```yaml
# analysis_options.yaml — if you keep prefer_abstract_final_static_class
linter:
  rules:
    avoid_classes_with_only_static_members: false
```
:::

## Why use this rule

Marking a static-only class as `abstract final` makes the intent clear: it is a namespace for constants or utility functions, not something to instantiate or extend. This prevents misuse and documents the design decision directly in the class declaration.

**See also:** [Dart language - Abstract classes](https://dart.dev/language/class-modifiers#abstract) | [Dart language - Final classes](https://dart.dev/language/class-modifiers#final)

## Don't

```dart
class BadConstants {
  static const pi = 3.14159;
  static const e = 2.71828;
}

class BadUtils {
  static String greet(String name) => 'Hello, $name!';
  static int add(int a, int b) => a + b;
}
```

## Do

```dart
abstract final class GoodConstants {
  static const pi = 3.14159;
  static const e = 2.71828;
}

abstract final class GoodUtils {
  static String greet(String name) => 'Hello, $name!';
  static int add(int a, int b) => a + b;
}

// Classes with instance members are fine:
class MixedClass {
  final String name;
  MixedClass(this.name);
  static const defaultName = 'World';
}

// Classes with constructors are fine:
class WithConstructor {
  WithConstructor._();
  static const value = 42;
}
```

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_abstract_final_static_class: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_abstract_final_static_class: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
