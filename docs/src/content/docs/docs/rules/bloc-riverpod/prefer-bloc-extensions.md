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

This rule flags `BlocProvider.of<T>(context)` and `RepositoryProvider.of<T>(context)`, and offers a quick fix rewriting them to `context.read<T>()`. When `listen: true` is passed, the fix produces `context.watch<T>()` instead.

## Why use this rule

`BlocProvider.of` and the extensions do the same lookup, but the extension puts the subscription decision in the method name. With `of`, whether the widget rebuilds on state changes depends on a `listen:` argument that is easy to omit and easy to misread — and its default (`false`) is silent, so a widget that should rebuild simply never does.

**See also:** [BlocProvider](https://bloclibrary.dev/flutter-bloc-concepts/#blocprovider) | [context.read vs context.watch](https://bloclibrary.dev/flutter-bloc-concepts/#usage-1)

## Examples

### Dispatching an event

A one-off read in a callback becomes `context.read`:

```dart
// Don't
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class CounterEvent {}

class Increment extends CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
}

void onTap(BuildContext context) {
  BlocProvider.of<CounterBloc>(context).add(Increment());   // LINT
}
```

```dart
// Do
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class CounterEvent {}

class Increment extends CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
}

void onTap(BuildContext context) {
  context.read<CounterBloc>().add(Increment());
}
```

### `listen: true` becomes `watch`

Reading state in `build` needs a subscription, so the fix produces `watch`:

```dart
// Don't
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
}

Widget build(BuildContext context) {
  final count = BlocProvider.of<CounterCubit>(context, listen: true).state; // LINT
  return Text('$count');
}
```

```dart
// Do
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
}

Widget build(BuildContext context) {
  final count = context.watch<CounterCubit>().state;
  return Text('$count');
}
```

### Repositories too

`RepositoryProvider.of` is reported on the same terms:

```dart
// Don't
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserRepository {}

void load(BuildContext context) {
  final repo = RepositoryProvider.of<UserRepository>(context);   // LINT
}
```

```dart
// Do
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserRepository {}

void load(BuildContext context) {
  final repo = context.read<UserRepository>();
}
```

## Known limitations

Only `BlocProvider` and `RepositoryProvider` resolving to `package:flutter_bloc`, `package:bloc` or `package:provider` are matched. A project's own wrapper with an `of` static is not reported.

A dynamic `listen:` argument (`listen: shouldWatch`) is treated as `false`, since the rule can only read a boolean literal — so the fix would produce `read` where `watch` may be wanted.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_bloc_extensions: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_bloc_extensions: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_bloc_public_methods`](/many_lints/docs/rules/bloc-riverpod/avoid-bloc-public-methods/) — Prevent public methods, getters, and setters in Bloc classes.
- [`avoid_passing_bloc_to_bloc`](/many_lints/docs/rules/bloc-riverpod/avoid-passing-bloc-to-bloc/) — Prevent Bloc/Cubit classes from depending on other Bloc/Cubit instances.
- [`avoid_duplicate_bloc_event_handlers`](/many_lints/docs/rules/bloc-riverpod/avoid-duplicate-bloc-event-handlers/) — Register each bloc event type exactly once.
- [`emit_new_bloc_state_instances`](/many_lints/docs/rules/bloc-riverpod/emit-new-bloc-state-instances/) — Emit a new state instance instead of the existing state object.
