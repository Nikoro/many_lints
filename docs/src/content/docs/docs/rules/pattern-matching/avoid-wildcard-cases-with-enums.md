---
title: avoid_wildcard_cases_with_enums
description: "Keep exhaustiveness checking by listing enum cases explicitly"
sidebar:
  label: avoid_wildcard_cases_with_enums
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Pattern Matching</span>

This rule flags a `_` or `default` case in a switch over a non-nullable enum.

## Why use this rule

A switch over an enum with no catch-all is checked for exhaustiveness: add a constant and the compiler points at every switch that must now handle it. A wildcard case turns that off permanently — new constants fall into the catch-all and inherit behaviour written for cases nobody had in mind, and the bug shows up at runtime.

**See also:** [Dart: exhaustiveness checking](https://dart.dev/language/branches#exhaustiveness-checking)

## Don't

```dart
enum Status { active, inactive, pending }

String describe(Status status) => switch (status) {
  Status.active => 'Active',
  // Add a constant to Status and it silently becomes 'Other'
  _ => 'Other',                       // LINT
};
```

## Do

```dart
String describe(Status status) => switch (status) {
  Status.active => 'Active',
  Status.inactive => 'Inactive',
  Status.pending => 'Pending',
};
```

If several constants share behaviour, group them with `||` and keep the check:

```dart
String describe(Status status) => switch (status) {
  Status.active => 'Active',
  Status.inactive || Status.pending => 'Not active',
};
```

## In a switch statement

Both `default:` and `case _:` are reported:

```dart
// Don't
void handle(Status status) {
  switch (status) {
    case Status.active:
      start();
    default:                          // LINT
      stop();
  }
}

// Do
void handle(Status status) {
  switch (status) {
    case Status.active:
      start();
    case Status.inactive:
    case Status.pending:
      stop();
  }
}
```

## Known limitations

The rule stays silent where a catch-all is legitimate:

- **Nullable enums.** `Status?` needs a case for `null`, and `_` is a reasonable way to write it.
- **Guarded wildcards.** `_ when flag => ...` is conditional, so the compiler still checks the remaining constants.
- **Non-enum switches**, including sealed class hierarchies, which are outside this rule's scope.

## Configuration

This rule appears only in the **`pedantic`** preset, because catch-all behaviour
is sometimes the contract — mapping every unsupported HTTP method to one
response, for instance.

Enable it by name:

```yaml
# many_lints.yaml
rules:
  avoid_wildcard_cases_with_enums: true
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_wildcard_pattern`](/many_lints/docs/rules/pattern-matching/prefer-wildcard-pattern/) — **Opposing convention.** Use the wildcard pattern '_' instead of 'Object()' for catch-all cases.
- [`prefer_switch_with_enums`](/many_lints/docs/rules/pattern-matching/prefer-switch-with-enums/) — Use a switch instead of an if-else chain over enum constants.
- [`avoid_single_field_destructuring`](/many_lints/docs/rules/pattern-matching/avoid-single-field-destructuring/) — Avoid destructuring a single field when direct property access is simpler.
- [`use_existing_destructuring`](/many_lints/docs/rules/pattern-matching/use-existing-destructuring/) — Add properties to an existing destructuring instead of accessing them directly.
