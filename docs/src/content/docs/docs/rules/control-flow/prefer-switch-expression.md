---
title: prefer_switch_expression
description: "Suggest converting switch statements to switch expressions"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_switch_expression
---

<span class="rule-badge rule-badge--version">v0.3.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

Warns when a switch statement can be converted to a switch expression. This applies when all branches either return a value or assign to the same variable, with each case containing exactly one statement.

## Why use this rule

Dart 3 introduced switch expressions as a more concise alternative to switch statements for simple value-producing switches. They reduce boilerplate (`case`, `return`, `break`), make it clear that the switch produces a value, and are easier to read when each branch is a single expression. The quick fix handles the conversion automatically.

**See also:** [Switch expressions](https://dart.dev/language/branches#switch-expressions)

## Don't

```dart
// All cases return a value — use switch expression
DeliveryIcon iconForBad(DeliveryStage stage) {
  switch (stage) {
    case DeliveryStage.packed:
      return DeliveryIcon.box;
    case DeliveryStage.shipped:
      return DeliveryIcon.truck;
    case DeliveryStage.delivered:
      return DeliveryIcon.home;
  }
}

// All cases assign to the same variable
String getDescriptionBad(DeliveryIcon icon) {
  String description;
  switch (icon) {
    case DeliveryIcon.box:
      description = 'Waiting in the warehouse';
    case DeliveryIcon.truck:
      description = 'On the road';
    case DeliveryIcon.home:
      description = 'Dropped at the door';
  }
  return description;
}
```

## Do

```dart
// Switch expression with return
DeliveryIcon iconForGood(DeliveryStage stage) {
  return switch (stage) {
    DeliveryStage.packed => DeliveryIcon.box,
    DeliveryStage.shipped => DeliveryIcon.truck,
    DeliveryStage.delivered => DeliveryIcon.home,
  };
}

// Switch expression with assignment
String getDescriptionGood(DeliveryIcon icon) {
  final description = switch (icon) {
    DeliveryIcon.box => 'Waiting in the warehouse',
    DeliveryIcon.truck => 'On the road',
    DeliveryIcon.home => 'Dropped at the door',
  };
  return description;
}

// Switch expression with default case (using wildcard)
String getNameGood(int value) {
  return switch (value) {
    1 => 'one',
    2 => 'two',
    _ => 'unknown',
  };
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_switch_expression: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

### Options

Configure in `many_lints.yaml` at your package root:

```yaml
rules:
  prefer_switch_expression:
    allow_fallthrough_cases: true
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `allow_fallthrough_cases` | bool | `false` | Also report switches where labels share a body. The quick fix merges them into a single `case a || b` pattern; a *trailing* fallthrough has nothing to merge into and stays unreported |

Alternatively, use a top-level `many_lints:` section in `analysis_options.yaml`.
Note this section does **not** inherit through `include:`; when both sources
exist, `many_lints.yaml` wins and the section is ignored entirely.
