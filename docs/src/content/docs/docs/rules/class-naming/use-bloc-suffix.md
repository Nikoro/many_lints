---
title: use_bloc_suffix
description: "Use Bloc suffix"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: use_bloc_suffix
---

| Property | Value |
|----------|-------|
| **Rule name** | `use_bloc_suffix` |
| **Category** | Class Naming |
| **Severity** | Warning |
| **Has quick fix** | Yes |

## Problem

Use Bloc suffix

## Suggestion

Ex. {0}Bloc

## Example

```dart
import 'package:bloc/bloc.dart';

// use_bloc_suffix
//
// Classes extending Bloc should have the 'Bloc' suffix.

abstract class CounterEvent {}

class Increment extends CounterEvent {}

// LINT: Missing 'Bloc' suffix
class CounterManager extends Bloc<CounterEvent, int> {
  CounterManager() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
  }
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      use_bloc_suffix: false
```
