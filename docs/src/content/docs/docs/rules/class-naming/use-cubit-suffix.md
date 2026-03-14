---
title: use_cubit_suffix
description: "Use Cubit suffix"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: use_cubit_suffix
---

| Property | Value |
|----------|-------|
| **Rule name** | `use_cubit_suffix` |
| **Category** | Class Naming |
| **Severity** | Warning |
| **Has quick fix** | Yes |

## Problem

Use Cubit suffix

## Suggestion

Ex. {0}Cubit

## Example

```dart
import 'package:bloc/bloc.dart';

// use_cubit_suffix
//
// Classes extending Cubit should have the 'Cubit' suffix.

// LINT: Missing 'Cubit' suffix
class Counter extends Cubit<int> {
  Counter() : super(0);

  void increment() => emit(state + 1);
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      use_cubit_suffix: false
```
