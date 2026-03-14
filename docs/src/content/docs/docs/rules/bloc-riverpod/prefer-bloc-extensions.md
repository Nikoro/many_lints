---
title: prefer_bloc_extensions
description: "Use 'context.{0}' instead of '{1}.of()'."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_bloc_extensions
---

| Property | Value |
|----------|-------|
| **Rule name** | `prefer_bloc_extensions` |
| **Category** | Bloc / Riverpod |
| **Severity** | Warning |
| **Has quick fix** | Yes |

## Problem

Use 'context.{0}' instead of '{1}.of()'.

## Suggestion

Replace with 'context.{0}{2}()'.

## Example

```dart
// ignore_for_file: unused_local_variable

// prefer_bloc_extensions
//
// Warns when BlocProvider.of() or RepositoryProvider.of() is used
// instead of context.read() / context.watch() extensions.

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
}

class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
}

class MyRepository {}

// ❌ Bad: Using BlocProvider.of() directly
void badExamples(BuildContext context) {
  // LINT: Use context.read instead of BlocProvider.of
  final bloc = BlocProvider.of<CounterBloc>(context);

  // LINT: Use context.read instead of BlocProvider.of (without type arg)
  BlocProvider.of(context);

  // LINT: Use context.watch instead (listen: true → context.watch)
  final watchedBloc = BlocProvider.of<CounterCubit>(context, listen: true);

  // LINT: Use context.read instead of RepositoryProvider.of
  final repo = RepositoryProvider.of<MyRepository>(context);
}

// ✅ Good: Using context extensions
void goodExamples(BuildContext context) {
  final bloc = context.read<CounterBloc>();
  final cubit = context.watch<CounterCubit>();
  final repo = context.read<MyRepository>();
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_bloc_extensions: false
```
