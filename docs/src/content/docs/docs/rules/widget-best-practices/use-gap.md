---
title: use_gap
description: "Use Gap widget instead of {0} for spacing in multi-child widgets."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: use_gap
---

| Property | Value |
|----------|-------|
| **Rule name** | `use_gap` |
| **Category** | Widget Best Practices |
| **Severity** | Warning |
| **Has quick fix** | Yes |

## Problem

Use Gap widget instead of {0} for spacing in multi-child widgets.

## Suggestion

Replace with Gap widget from the gap package.

## Example

```dart
import 'package:flutter/material.dart';

// use_gap
//
// Use Gap widget instead of SizedBox or Padding for spacing
// inside multi-child widgets like Column, Row, etc.

class UseGapExample extends StatelessWidget {
  const UseGapExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('First'),
        // LINT: Use Gap instead of SizedBox for vertical spacing
        SizedBox(height: 16),
        Text('Second'),
        // LINT: Use Gap instead of Padding for vertical spacing
        Padding(padding: EdgeInsets.only(top: 8)),
        Text('Third'),
      ],
    );
  }
}

class UseGapRowExample extends StatelessWidget {
  const UseGapRowExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Left'),
        // LINT: Use Gap instead of SizedBox for horizontal spacing
        SizedBox(width: 8),
        Text('Right'),
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
      use_gap: false
```
