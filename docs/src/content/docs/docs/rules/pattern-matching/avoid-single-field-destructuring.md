---
title: avoid_single_field_destructuring
description: "Avoid destructuring a single field when direct property access is simpler."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_single_field_destructuring
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Pattern Matching</span>

This rule flags a pattern declaration that pulls out exactly one field. `final User(:name) = user;` is pattern syntax doing the job of `final name = user.name;`, and the quick fix rewrites it to that.

Destructuring pays for itself from two fields upward. At one, it is a longer way to write a property read.

**See also:** [Dart patterns](https://dart.dev/language/patterns)

## Don't

```dart
class User {
  const User({required this.name, required this.email});

  final String name;
  final String email;
}

void greet(User user) {
  final User(:name) = user;                 // LINT
  print('Hello, $name');
}

void mail(User user) {
  final User(email: address) = user;        // LINT — renaming does not help
  print(address);
}
```

## Do

```dart
void greet(User user) {
  final name = user.name;
  print('Hello, $name');
}

void mail(User user) {
  final address = user.email;
  print(address);
}
```

## Records too

A record pattern binding one field is the same shape and is reported the same way:

```dart
// Don't
void report(({int length, String path}) file) {
  final (:length) = file;                   // LINT
  print(length);
}

// Do
void report(({int length, String path}) file) {
  final length = file.length;
  print(length);
}
```

## When destructuring is the right call

Two or more fields, and the pattern earns its place — nothing is reported:

```dart
void summary(User user) {
  final User(:name, :email) = user;
  print('$name <$email>');
}

void report(({int length, String path}) file) {
  final (:length, :path) = file;
  print('$path is $length bytes');
}
```

## Known limitations

**Only pattern *declarations* are checked** — a `final`/`var` binding with a pattern on the left. A single-field pattern in a `switch` case or an `if-case` is doing matching work as well as extraction, so it is never reported:

```dart
// Not reported — the pattern also decides whether the branch runs
if (payload case Response(:final body)) {
  print(body);
}

switch (event) {
  case KeyEvent(:final key):
    print(key);
}
```

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  avoid_single_field_destructuring: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  avoid_single_field_destructuring: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`use_existing_destructuring`](/many_lints/docs/rules/pattern-matching/use-existing-destructuring/) — Add properties to an existing destructuring instead of accessing them directly.
- [`avoid_wildcard_cases_with_enums`](/many_lints/docs/rules/pattern-matching/avoid-wildcard-cases-with-enums/) — Keep exhaustiveness checking by listing enum cases explicitly.
- [`prefer_switch_with_enums`](/many_lints/docs/rules/pattern-matching/prefer-switch-with-enums/) — Use a switch instead of an if-else chain over enum constants.
- [`prefer_wildcard_pattern`](/many_lints/docs/rules/pattern-matching/prefer-wildcard-pattern/) — Use the wildcard pattern '_' instead of 'Object()' for catch-all cases.
