---
title: avoid_unnecessary_consumer_widgets
description: "ConsumerWidget does not use WidgetRef. Consider using StatelessWidget instead."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_unnecessary_consumer_widgets
---

| Property | Value |
|----------|-------|
| **Rule name** | `avoid_unnecessary_consumer_widgets` |
| **Category** | Widget Best Practices |
| **Severity** | Warning |
| **Has quick fix** | Yes |

## Problem

ConsumerWidget does not use WidgetRef. Consider using StatelessWidget instead.

## Suggestion

Change the base class and remove unused ref parameter.

## Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// avoid_unnecessary_consumer_widgets
//
// ConsumerWidget should only be used when the WidgetRef is actually used.
// If ref is unused, use StatelessWidget instead.

// LINT: ConsumerWidget does not use WidgetRef
class AvoidUnnecessaryConsumerWidgetsExample extends ConsumerWidget {
  const AvoidUnnecessaryConsumerWidgetsExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref is never used here
    return Text('Hello');
  }
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_unnecessary_consumer_widgets: false
```
