---
title: avoid_unnecessary_enum_prefix
description: "Drop an enum name repeated in its own constants"
sidebar:
  label: avoid_unnecessary_enum_prefix
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Class Naming</span>

Flags an enum constant that repeats the name of its own enum.

`enum Status { statusActive }` reads as `Status.statusActive` at every call site, where the type already says `Status`. The prefix is a habit carried over from languages whose enum constants share one namespace; Dart scopes them to the enum, so it buys nothing and lengthens every use.

This rule is in the **`opinionated`** preset, and takes no configuration.

## Don't

```dart
enum Status {
  statusActive,
  statusArchived,
}

// Every use repeats the type name.
final state = Status.statusActive;
```

## Do

```dart
enum Status {
  active,
  archived,
}

final state = Status.active;
```

## Examples

### Dot shorthands read properly once the prefix is gone

Dropping it is what makes Dart 3.10's shorthand usable — `.active` rather than `.statusActive`:

```dart
enum Status { active, archived }

void setStatus(Status status) {}

void main() {
  setStatus(.active);
}
```

### A constant named exactly like its enum is left alone

`Status.status` is the whole word, not a prefix, so there is nothing to strip:

```dart
enum Status {
  status,   // Accepted
  active,
}
```

### The prefix has to end at a word boundary

A constant that merely *starts* with the same letters is not prefixed by them:

```dart
enum Status {
  statusable,   // Accepted — `able` does not begin a new word
  statusActive, // LINT — `Active` does
}
```

## Known limitations

**Enums only.** A class of `static const` values used as an enum substitute is not checked.

**No quick fix.** Renaming a constant touches every call site and every `switch` arm that names it, which is a rename refactoring rather than a one-file edit.

**See also:** [Enumerated types](https://dart.dev/language/enums)

## Turning this rule off

To disable this rule:

```yaml
# many_lints.yaml
rules:
  avoid_unnecessary_enum_prefix: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`use_class_prefix`](/many_lints/docs/rules/class-naming/use-class-prefix/) — Require a name prefix for classes deriving from a configured type.
- [`match_class_name_pattern`](/many_lints/docs/rules/class-naming/match-class-name-pattern/) — Match class names against a regular expression.
- [`prefer_boolean_prefixes`](/many_lints/docs/rules/class-naming/prefer-boolean-prefixes/) — Name booleans as questions.
- [`prefer_correct_callback_field_name`](/many_lints/docs/rules/class-naming/prefer-correct-callback-field-name/) — Name callbacks onSomething, the way Flutter does.
