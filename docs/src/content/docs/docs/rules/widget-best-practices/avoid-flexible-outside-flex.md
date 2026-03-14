---
title: avoid_flexible_outside_flex
description: "{0} should only be used as a direct child of Row, Column, or Flex."
sidebar:
  label: avoid_flexible_outside_flex
---

| Property | Value |
|----------|-------|
| **Rule name** | `avoid_flexible_outside_flex` |
| **Category** | Widget Best Practices |
| **Severity** | Warning |
| **Has quick fix** | No |

## Problem

{0} should only be used as a direct child of Row, Column, or Flex.

## Suggestion

Move {0} inside a Row, Column, or Flex, or remove the wrapper.

## Example

```dart
import 'package:flutter/material.dart';

// avoid_flexible_outside_flex
//
// Flexible and Expanded widgets should only be used as direct children
// of Row, Column, or Flex. Using them elsewhere has no effect.

// ❌ Bad: Expanded/Flexible outside a Flex widget
class BadExamples extends StatelessWidget {
  const BadExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // LINT: Expanded wrapped inside a Container, not directly in a Flex
        Container(child: Expanded(child: Text('hello'))),

        // LINT: Flexible inside a Center
        Center(child: Flexible(child: Text('hello'))),

        // LINT: Expanded inside a Padding
        Padding(
          padding: EdgeInsets.all(8),
          child: Expanded(child: Text('hello')),
        ),
      ],
    );
  }
}

// ✅ Good: Expanded/Flexible as direct children of Row, Column, or Flex
class GoodExamples extends StatelessWidget {
  const GoodExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // OK: Expanded directly in a Row
        Row(children: [Expanded(child: Text('hello'))]),

        // OK: Flexible directly in a Column
        Flexible(child: Text('hello')),

        // OK: Multiple Expanded in a Row
        Row(
          children: [
            Expanded(child: Text('a')),
            Expanded(child: Text('b')),
          ],
        ),
      ],
    );
  }
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_flexible_outside_flex: false
```
