---
title: avoid_cascade_after_if_null
description: "Detect cascades after if-null operators without parentheses"
sidebar:
  label: avoid_cascade_after_if_null
---

<span class="rule-badge rule-badge--version">v0.3.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

Warns when a cascade expression (`..`) follows an if-null (`??`) operator without parentheses. Due to operator precedence, it is ambiguous whether the cascade applies to the right-hand side of `??` or to the entire expression, which can produce unexpected results.

## Why use this rule

Dart's cascade operator and if-null operator have surprising precedence interactions. Without parentheses, `a ?? B()..method()` is parsed as `a ?? (B()..method())`, which may not be what the developer intended. Adding explicit parentheses makes the intent clear and prevents subtle bugs.

**See also:** [Cascade notation](https://dart.dev/language/operators#cascade-notation)

## Don't

```dart
void bad(Cow? nullableCow) {
  // Unclear whether ..moo() applies to the result of ?? or just Cow()
  final cow = nullableCow ?? Cow()
    ..moo();

  // Multiple cascades after if-null
  final cow2 = nullableCow ?? Cow()
    ..moo()
    ..age = 5;
}
```

## Do

```dart
void good(Cow? nullableCow) {
  // Cascade applies to the entire if-null expression
  final cow = (nullableCow ?? Cow())..moo();

  // Cascade applies only to the new instance
  final cow2 = nullableCow ?? (Cow()..moo());

  // No if-null involved, cascade is unambiguous
  final cow3 = Cow()..moo();
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_cascade_after_if_null: false
```
