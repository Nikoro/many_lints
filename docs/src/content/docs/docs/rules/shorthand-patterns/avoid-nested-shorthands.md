---
title: avoid_nested_shorthands
description: "Avoid nesting a dot shorthand inside another dot shorthand invocation."
sidebar:
  label: avoid_nested_shorthands
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Shorthand Patterns</span>

Flags a dot shorthand that appears inside the arguments of another dot shorthand invocation. A single shorthand is readable because the surrounding declaration supplies the type name, but once shorthands nest, that anchor is gone and you end up with expressions like `.new(.new(version: .new('val')))`.

## Why use this rule

A dot shorthand omits the type name on the promise that context makes it obvious. That promise holds for the outermost expression — its type comes from the variable, parameter, or return type sitting right next to it. It breaks for the inner ones: their types come from the *outer constructor's signature*, which is not on the screen. A reader has to look up each parameter's declared type to find out what is being built.

The rule reports each nested shorthand rather than the outer one, so the fix stays local — name the type on the inner expression and the outer shorthand keeps its brevity.

All three shorthand forms are covered, since each drops the type name for the same reason: constructor invocations (`.new(...)`, `.filled(...)`), static method invocations (`.make(...)`), and property accesses (`.zero`).

**See also:** [Dart language — dot shorthands](https://dart.dev/language/dot-shorthands)

## Don't

```dart
class SomeClass {
  final String value;
  const SomeClass(this.value);
}

class Some {
  final SomeClass version;
  const Some({required this.version});
  static const Some empty = Some(version: SomeClass(''));
}

class Another {
  final Some some;
  Another(this.some);
}

void fn() {
  // Nothing here names a type — every level is a `.new`.
  final Another a = .new(.new(version: .new('val')));

  // The nested shorthand's type comes from `Another`'s parameter list,
  // which the reader cannot see from here.
  final Another b = .new(.empty);
}
```

## Do

```dart
void fn() {
  // The outer shorthand still drops `Another`; the inner types are named.
  final Another a = .new(Some(version: SomeClass('val')));

  // Naming the outer type instead is equally fine — only nesting is flagged.
  final b = Another(.new(version: SomeClass('val')));

  final Another c = .new(Some.empty);

  // Shorthands that are siblings rather than nested are not flagged:
  final Some d = .empty;
  final Another e = .new(d);
}
```

## Configuration

This rule is in the **`opinionated`** preset. With a lower preset, enable it by
name:

```yaml
# many_lints.yaml
rules:
  avoid_nested_shorthands: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  avoid_nested_shorthands: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
