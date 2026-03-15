---
title: prefer_bloc_extensions
description: "Use context.read/watch instead of BlocProvider.of or RepositoryProvider.of"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_bloc_extensions
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Bloc / Riverpod</span>

This rule flags usage of `BlocProvider.of()` and `RepositoryProvider.of()` and suggests using the shorter `context.read()` or `context.watch()` extensions instead. When `listen: true` is passed, the rule suggests `context.watch()`.

## Why use this rule

The `context.read()` and `context.watch()` extensions are shorter, more readable, and make the intent clearer. With `BlocProvider.of()`, developers can easily forget the `listen` parameter or misconfigure it. The extension methods make the distinction between one-time reads and reactive watches explicit in the method name itself.

**See also:** [BlocProvider](https://bloclibrary.dev/flutter-bloc-concepts/#blocprovider) | [context.read vs context.watch](https://bloclibrary.dev/flutter-bloc-concepts/#usage-1)

## Don't

```dart
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

void examples(BuildContext context) {
  final bloc = BlocProvider.of<CounterBloc>(context);
  final watched = BlocProvider.of<CounterCubit>(context, listen: true);
  final repo = RepositoryProvider.of<MyRepository>(context);
}
```

## Do

```dart
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

void examples(BuildContext context) {
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
