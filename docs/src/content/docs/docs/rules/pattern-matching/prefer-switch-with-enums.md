---
title: prefer_switch_with_enums
description: "Use a switch instead of an if-else chain over enum constants"
sidebar:
  label: prefer_switch_with_enums
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Pattern Matching</span>

This rule flags an if-else chain of three or more branches that compares the same enum value against different constants.

## Why use this rule

A `switch` over an enum is checked for exhaustiveness. Add a constant to the enum and the compiler points at every switch that must now handle it, turning the change into a guided refactor.

An if-else chain gets no such check. A new constant falls through to the final `else`, or past the chain entirely, and the bug shows up at runtime in whichever branch forgot about it. The chain is also longer to read: the reader has to confirm each branch tests the same subject.

**See also:** [Dart: exhaustiveness checking](https://dart.dev/language/branches#exhaustiveness-checking)

## Don't

```dart
String describe(Status status) {
  if (status == Status.active) {
    return 'Active';
  } else if (status == Status.inactive) {
    return 'Inactive';
  } else if (status == Status.pending) {
    return 'Pending';
  }
  return '';
}
```

## Do

```dart
String describe(Status status) => switch (status) {
  Status.active => 'Active',
  Status.inactive => 'Inactive',
  Status.pending => 'Pending',
};
```

## Known limitations

The rule requires the whole chain to be replaceable, so it stays silent when:

- Fewer than three branches compare enum constants — a short chain is not worth restructuring.
- The branches test different subjects, or mix an enum comparison with an unrelated condition.
- The enum is nullable, since a `null` case needs handling a plain switch over constants does not give.

Operand order does not matter: `Status.active == status` is recognised the same as `status == Status.active`.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_switch_with_enums: false
```
