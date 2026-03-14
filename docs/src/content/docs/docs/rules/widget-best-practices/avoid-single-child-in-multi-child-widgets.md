---
title: avoid_single_child_in_multi_child_widgets
description: "Avoid using {0} with a single child."
sidebar:
  label: avoid_single_child_in_multi_child_widgets
---

| Property | Value |
|----------|-------|
| **Rule name** | `avoid_single_child_in_multi_child_widgets` |
| **Category** | Widget Best Practices |
| **Severity** | Warning |
| **Has quick fix** | No |

## Problem

Avoid using {0} with a single child.

## Suggestion

Remove the {0} and achieve the same result using dedicated widgets.

## Example

```dart
import 'package:flutter/material.dart';

// avoid_single_child_in_multi_child_widgets
//
// Multi-child widgets like Column, Row, Wrap should not be used
// with only a single child. Use the child widget directly instead.

class AvoidSingleChildExample extends StatelessWidget {
  const AvoidSingleChildExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        // LINT: Column with a single child
        children: [Text('I am the only child')],
      ),
    );
  }
}

class AvoidSingleChildRowExample extends StatelessWidget {
  const AvoidSingleChildRowExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      // LINT: Row with a single child
      children: [Text('I am the only child')],
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
      avoid_single_child_in_multi_child_widgets: false
```
