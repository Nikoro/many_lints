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
AssetSensorType convertBad(AssetSensorCategory sensorCategory) {
  switch (sensorCategory) {
    case AssetSensorCategory.vibration:
      return AssetSensorType.first;
    case AssetSensorCategory.energy:
      return AssetSensorType.second;
    case AssetSensorCategory.temperature:
      return AssetSensorType.third;
  }
}

// All cases assign to the same variable
String getDescriptionBad(AssetSensorType type) {
  String description;
  switch (type) {
    case AssetSensorType.first:
      description = 'First sensor';
    case AssetSensorType.second:
      description = 'Second sensor';
    case AssetSensorType.third:
      description = 'Third sensor';
  }
  return description;
}
```

## Do

```dart
// Switch expression with return
AssetSensorType convertGood(AssetSensorCategory sensorCategory) {
  return switch (sensorCategory) {
    AssetSensorCategory.vibration => AssetSensorType.first,
    AssetSensorCategory.energy => AssetSensorType.second,
    AssetSensorCategory.temperature => AssetSensorType.third,
  };
}

// Switch expression with assignment
String getDescriptionGood(AssetSensorType type) {
  final description = switch (type) {
    AssetSensorType.first => 'First sensor',
    AssetSensorType.second => 'Second sensor',
    AssetSensorType.third => 'Third sensor',
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
