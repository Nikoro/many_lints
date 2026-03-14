---
title: prefer_single_widget_per_file
description: "Only one public widget per file. Move additional widgets to separate files."
sidebar:
  label: prefer_single_widget_per_file
---

| Property | Value |
|----------|-------|
| **Rule name** | `prefer_single_widget_per_file` |
| **Category** | Widget Best Practices |
| **Severity** | Warning |
| **Has quick fix** | No |

## Problem

Only one public widget per file. Move additional widgets to separate files.

## Suggestion

Move this widget to its own file.

## Example

```dart
import 'package:flutter/material.dart';

// prefer_single_widget_per_file
//
// Warns when a file contains more than one public widget class.
// Private widgets (prefixed with underscore) are ignored.

// ❌ Bad: Multiple public widgets in a single file
// The first widget is fine, but the second one triggers the lint.

class FirstWidget extends StatelessWidget {
  const FirstWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('First');
  }
}

// LINT: Only one public widget per file
class SecondWidget extends StatelessWidget {
  const SecondWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Second');
  }
}

// ✅ Good: Private widgets are allowed alongside a public widget
class _HelperWidget extends StatelessWidget {
  const _HelperWidget();

  @override
  Widget build(BuildContext context) {
    return const Text('Helper');
  }
}

// ✅ Good: Non-widget classes are allowed alongside a public widget
class MyModel {
  final String name;
  const MyModel(this.name);
}

// ✅ Good: StatefulWidget with its private State class is fine
// (State classes are private and extend State, not Widget directly)
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_single_widget_per_file: false
```
