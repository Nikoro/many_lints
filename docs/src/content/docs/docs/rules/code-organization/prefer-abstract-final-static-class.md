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

Flags a class that holds only static members but is not declared `abstract final`.

Without those modifiers the class can be instantiated and subclassed. `AppColors()` compiles and yields a useless empty object; `class MyColors extends AppColors` compiles and inherits nothing. Marking it `abstract final` makes both a compile error and states in the declaration that this is a namespace, not a type.

A quick fix adds the modifiers.

This rule is in the **`opinionated`** preset, so it is on with `preset: opinionated` or `preset: pedantic`.

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

**See also:** [Dart language - Abstract classes](https://dart.dev/language/class-modifiers#abstract) | [Dart language - Final classes](https://dart.dev/language/class-modifiers#final)

## Don't

```dart
class AppSpacing {
  static const small = 4.0;
  static const medium = 8.0;
  static const large = 16.0;
}
```

## Do

```dart
abstract final class AppSpacing {
  static const small = 4.0;
  static const medium = 8.0;
  static const large = 16.0;
}
```

## Examples

### A utility namespace is the same case

Static methods count exactly as static fields do:

```dart
// Don't
class StringUtils {
  static String slugify(String input) => input.toLowerCase();

  static String truncate(String input, int max) =>
      input.length <= max ? input : input.substring(0, max);
}
```

```dart
// Do
abstract final class StringUtils {
  static String slugify(String input) => input.toLowerCase();

  static String truncate(String input, int max) =>
      input.length <= max ? input : input.substring(0, max);
}
```

### A single instance member exempts the class

The rule fires only when *every* member is static. One instance field or method means the class is a real type and is left alone:

```dart
// Accepted — `name` is an instance field
class Environment {
  const Environment(this.name);

  final String name;

  static const production = Environment('prod');
  static const staging = Environment('staging');
}
```

### The older private-constructor idiom is still reported

`ClassName._()` guards against instantiation, but it does not block subclassing and it costs a line. The rule reports it and the quick fix **deletes the constructor** while adding the modifiers:

```dart
// Don't
class ApiRoutes {
  ApiRoutes._();

  static const login = '/auth/login';
  static const logout = '/auth/logout';
}
```

```dart
// Do
abstract final class ApiRoutes {
  static const login = '/auth/login';
  static const logout = '/auth/logout';
}
```

Only a *trivial* private constructor is treated this way — parameterless, no `const`, no `factory`, no initializers, no redirect and an empty body. Anything richer is doing real work, so the class is left alone.

## Known limitations

**Any non-trivial constructor exempts the class.** A public one, or a private one taking parameters or running a body, means the class is meant to be constructed, so the rule steps back.

**`sealed`, `base`, `interface` and `mixin` classes are skipped.** Each already carries a decision about extension that `abstract final` would contradict.

**Only classes are checked.** A mixin, extension or enum holding static members is a different construct and is never reported.

**An empty class is never reported** — and neither is one holding *only* a private constructor, since there is no static member to namespace.

## Configuration

To turn it off:

```yaml
# many_lints.yaml
rules:
  prefer_abstract_final_static_class: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`arguments_ordering`](/many_lints/docs/rules/code-organization/arguments-ordering/) — Keep named arguments in a configured order.
- [`avoid_duplicate_mixins`](/many_lints/docs/rules/code-organization/avoid-duplicate-mixins/) — Flag a mixin applied twice in one `with` clause.
- [`avoid_generics_shadowing`](/many_lints/docs/rules/code-organization/avoid-generics-shadowing/) — Avoid generic type parameters that shadow top-level declarations.
- [`avoid_unnecessary_constructor`](/many_lints/docs/rules/code-organization/avoid-unnecessary-constructor/) — Remove a constructor identical to the default one.
