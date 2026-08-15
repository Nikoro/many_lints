---
title: prefer_immutable_bloc_state
description: "Ensure Bloc and Cubit state classes are annotated with @immutable"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_immutable_bloc_state
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Bloc / Riverpod</span>

This rule flags a Bloc or Cubit state class that is missing the `@immutable` annotation. The state class is recognised through the type argument of `Bloc<Event, State>` or `Cubit<State>`, and the check is then widened to every subclass and implementor.

## Why use this rule

`emit` compares the new state against the current one and does nothing when they are equal. Mutating a state object in place therefore produces a state change no listener ever sees — the reference did not change, so `emit` discards it. The UI simply does not update, with no error to trace back to.

`@immutable` moves that failure to analysis time: the analyzer reports a non-final field where it is declared, rather than leaving the bug to be found in a running app.

**See also:** [Bloc state management](https://bloclibrary.dev/bloc-concepts/#state)

## Not for Riverpod or plain state classes

This rule recognises state **by type**, so it is completely inert in a project without the `bloc` package.

If you want the same advice for Riverpod notifier state, or for any class your project names `...State`, use [`prefer_immutable_state`](/many_lints/docs/rules/state-management/prefer-immutable-state/) instead. It matches on the class name and carries the `name_pattern` option.

Until v0.10.0 this rule did both, which meant a Riverpod-only codebase received "Bloc state" diagnostics for every class merely named `...State`. Splitting them means each rule now says what it actually checks.

## Don't

```dart
import 'package:bloc/bloc.dart';

sealed class CounterState {}

class CounterInitial extends CounterState {}

class CounterCubit extends Cubit<CounterState> {
  CounterCubit() : super(CounterInitial());
}
```

## Do

```dart
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

@immutable
sealed class CounterState {}

@immutable
class CounterInitial extends CounterState {}

class CounterCubit extends Cubit<CounterState> {
  CounterCubit() : super(CounterInitial());
}
```

## Turning this rule off

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_immutable_bloc_state: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
