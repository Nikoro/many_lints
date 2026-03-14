---
title: avoid_unnecessary_hook_widgets
description: "This HookWidget does not use hooks."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_unnecessary_hook_widgets
---

| Property | Value |
|----------|-------|
| **Rule name** | `avoid_unnecessary_hook_widgets` |
| **Category** | Widget Best Practices |
| **Severity** | Warning |
| **Has quick fix** | Yes |

## Problem

This HookWidget does not use hooks.

## Suggestion

Convert it to a StatelessWidget

## Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

// avoid_unnecessary_hook_widgets
//
// HookWidget should only be used when hooks are actually called.
// If no hooks are used, use StatelessWidget instead.

// LINT: HookWidget does not use any hooks
class AvoidUnnecessaryHookWidgetsExample extends HookWidget {
  const AvoidUnnecessaryHookWidgetsExample({super.key});

  @override
  Widget build(BuildContext context) {
    // No hooks called here
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
      avoid_unnecessary_hook_widgets: false
```
