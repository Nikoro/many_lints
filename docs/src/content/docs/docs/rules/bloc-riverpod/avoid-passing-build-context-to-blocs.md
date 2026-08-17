---
title: avoid_passing_build_context_to_blocs
description: "Prevent passing BuildContext to Bloc or Cubit classes"
sidebar:
  label: avoid_passing_build_context_to_blocs
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Bloc / Riverpod</span>

This rule flags Bloc or Cubit classes that accept a `BuildContext` as a constructor or method parameter. Blocs should remain independent of the UI layer and never hold a reference to a widget's context.

## Why use this rule

Passing `BuildContext` into a Bloc creates a dangerous coupling between your business logic and the widget tree. The context can become invalid (unmounted) while the Bloc is still alive, leading to runtime crashes. It also makes the Bloc impossible to unit test without mocking the entire widget framework. Any logic that needs the context (navigation, showing dialogs, reading theme) belongs in the widget layer, not in the Bloc.

**See also:** [Bloc best practices](https://bloclibrary.dev/bloc-concepts/)

## Don't

```dart
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';

abstract class CounterEvent {}

// Bloc constructor accepts BuildContext
class BadBloc extends Bloc<CounterEvent, int> {
  final BuildContext context;

  BadBloc(this.context) : super(0);
}

// Cubit method accepts BuildContext
class BadCubit extends Cubit<int> {
  BadCubit() : super(0);

  void doSomething(BuildContext context) {}
}

// Named constructor parameter with BuildContext
class AnotherBadBloc extends Bloc<CounterEvent, int> {
  AnotherBadBloc({required BuildContext context}) : super(0);
}
```

## Do

```dart
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';

abstract class CounterEvent {}

class Increment extends CounterEvent {}

// Bloc with repository dependency (no BuildContext)
class CounterRepository {
  int getValue() => 0;
}

class GoodBloc extends Bloc<CounterEvent, int> {
  final CounterRepository repository;

  GoodBloc(this.repository) : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
  }
}

// Cubit with no BuildContext dependency
class GoodCubit extends Cubit<int> {
  GoodCubit() : super(0);

  void increment() => emit(state + 1);
}
```

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`avoid_passing_build_context_to_blocs: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_passing_build_context_to_blocs: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_build_context_in_providers`](/many_lints/docs/rules/riverpod-state/avoid-build-context-in-providers/) — Providers outlive widgets, so they should not receive a BuildContext.
- [`never_discard_build_context`](/many_lints/docs/rules/widget-best-practices/never-discard-build-context/) — Don't discard a BuildContext parameter with a wildcard.
- [`use_closest_build_context`](/many_lints/docs/rules/widget-best-practices/use-closest-build-context/) — Use the inner BuildContext from builder callbacks, not the outer one.
- [`avoid_passing_bloc_to_bloc`](/many_lints/docs/rules/bloc-riverpod/avoid-passing-bloc-to-bloc/) — Prevent Bloc/Cubit classes from depending on other Bloc/Cubit instances.
