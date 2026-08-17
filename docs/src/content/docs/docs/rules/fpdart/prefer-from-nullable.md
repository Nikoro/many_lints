---
title: prefer_from_nullable
description: "A null check that builds an Option by hand is what Option.fromNullable is for"
sidebar:
  label: prefer_from_nullable
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">fpdart</span>

This rule flags a conditional that tests a value against `null` and builds `Option.of(value)` in one branch and a `None` in the other.

## Why use this rule

`Option.fromNullable` makes exactly this decision, so the conditional spells out a step the constructor already performs.

The manual form is not just longer — it names the value twice, once in the condition and once inside the `Some`. That is where the copy-paste bug lives: `name != null ? Option.of(other) : const None()` compiles cleanly and quietly wraps the wrong variable, or wraps one that is still nullable.

**See also:** [fpdart: `Option.fromNullable`](https://pub.dev/documentation/fpdart/latest/fpdart/Option/Option.fromNullable.html)

## Don't

```dart
final option = name != null ? Option.of(name) : Option<String>.none();
```

The inverted spelling is the same thing:

```dart
final option = name == null ? Option<String>.none() : Option.of(name);
```

## Do

```dart
final option = Option.fromNullable(name);
```

`optionOf(name)` is the shorthand for the same constructor.

## Quick fix

A quick fix replaces the whole conditional with `Option.fromNullable(value)`, re-deriving the tested value from the condition. It can be applied across a whole file at once.

## Known limitations

The `Some` branch must wrap the *same* expression the condition tested — compared by source text. When it wraps something else, the conditional is doing a different job and rewriting it would change behaviour, so the rule stays silent.

Only `Option` is covered. `Either.fromNullable` takes an `onNull` callback, so the equivalent conditional carries a value the rewrite would have to invent.

## Configuration

This rule is in the **`opinionated`** preset. With a lower preset, enable it by
name with `prefer_from_nullable: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  prefer_from_nullable: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
