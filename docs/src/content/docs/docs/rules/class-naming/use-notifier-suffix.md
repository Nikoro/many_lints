---
title: use_notifier_suffix
description: "Use Notifier suffix"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: use_notifier_suffix
---

| Property | Value |
|----------|-------|
| **Rule name** | `use_notifier_suffix` |
| **Category** | Class Naming |
| **Severity** | Warning |
| **Has quick fix** | Yes |

## Problem

Use Notifier suffix

## Suggestion

Ex. {0}Notifier

## Example

```dart
import 'package:riverpod/riverpod.dart';

// use_notifier_suffix
//
// Classes extending Notifier should have the 'Notifier' suffix.

// LINT: Missing 'Notifier' suffix
class CounterManager extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      use_notifier_suffix: false
```
