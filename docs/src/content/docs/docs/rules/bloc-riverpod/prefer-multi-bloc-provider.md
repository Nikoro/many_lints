---
title: prefer_multi_bloc_provider
description: "Use MultiBlocProvider, MultiBlocListener, or MultiRepositoryProvider instead of nesting"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_multi_bloc_provider
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Bloc / Riverpod</span>

This rule flags nested `BlocProvider`, `BlocListener`, or `RepositoryProvider` widgets that could be consolidated using their `Multi*` counterpart. It only triggers when the same type is nested (e.g., `BlocProvider` inside `BlocProvider`), not when mixing different types.

## Why use this rule

Deeply nested providers create a "pyramid of doom" that hurts readability and makes diffs harder to review. `MultiBlocProvider`, `MultiBlocListener`, and `MultiRepositoryProvider` flatten the nesting into a clean list, keeping the widget tree shallow and easy to scan. The behavior is identical -- it's purely a readability improvement.

**See also:** [MultiBlocProvider](https://bloclibrary.dev/flutter-bloc-concepts/#multiblocprovider) | [MultiBlocListener](https://bloclibrary.dev/flutter-bloc-concepts/#multibloclistener) | [MultiRepositoryProvider](https://bloclibrary.dev/flutter-bloc-concepts/#multirepositoryprovider)

## Don't

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
}

class TimerCubit extends Cubit<int> {
  TimerCubit() : super(0);
}

// Nested BlocProviders
final widget = BlocProvider<CounterBloc>(
  create: (context) => CounterBloc(),
  child: BlocProvider<TimerCubit>(
    create: (context) => TimerCubit(),
    child: Container(),
  ),
);
```

## Do

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
}

class TimerCubit extends Cubit<int> {
  TimerCubit() : super(0);
}

// Flattened with MultiBlocProvider
final widget = MultiBlocProvider(
  providers: [
    BlocProvider<CounterBloc>(create: (context) => CounterBloc()),
    BlocProvider<TimerCubit>(create: (context) => TimerCubit()),
  ],
  child: Container(),
);
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_multi_bloc_provider: false
```
