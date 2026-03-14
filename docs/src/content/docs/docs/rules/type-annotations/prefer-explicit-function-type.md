---
title: prefer_explicit_function_type
description: "This 'Function' type does not specify a return type or parameter list."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_explicit_function_type
---

| Property | Value |
|----------|-------|
| **Rule name** | `prefer_explicit_function_type` |
| **Category** | Type Annotations |
| **Severity** | Warning |
| **Has quick fix** | Yes |

## Problem

This 'Function' type does not specify a return type or parameter list.

## Suggestion

Try adding explicit return type and parameter list.

## Example

```dart
// ignore_for_file: unused_element, unused_field

/// Examples of the `prefer_explicit_function_type` lint rule.

// ❌ Bad: Using non-explicit Function type
class BadWidget {
  final Function onTap; // LINT
  final Function? onLongPress; // LINT

  const BadWidget(this.onTap, this.onLongPress);
}

void badFunction(Function callback) {} // LINT

Function badReturnType() {
  // LINT
  return () {};
}

void badTypeArgument() {
  List<Function> callbacks = []; // LINT
}

// ✅ Good: Using explicit function types
class GoodWidget {
  final void Function() onTap;
  final void Function()? onLongPress;

  const GoodWidget(this.onTap, this.onLongPress);
}

void goodFunction(void Function() callback) {}

void Function() goodReturnType() {
  return () {};
}

void goodTypeArgument() {
  List<void Function()> callbacks = [];
}

// ✅ Good: Function types with parameters and return types
class GoodWidgetWithTypes {
  final void Function(int value) onValueChanged;
  final int Function(String input) processInput;
  final String Function(int a, int b)? combine;

  const GoodWidgetWithTypes(
    this.onValueChanged,
    this.processInput,
    this.combine,
  );
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_explicit_function_type: false
```
