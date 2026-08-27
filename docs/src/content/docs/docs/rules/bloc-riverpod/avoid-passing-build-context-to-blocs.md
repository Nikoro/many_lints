---
title: avoid_passing_build_context_to_blocs
description: "Prevent passing BuildContext to Bloc or Cubit classes"
sidebar:
  label: avoid_passing_build_context_to_blocs
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Bloc / Riverpod</span>

This rule flags a `BuildContext` parameter on any constructor or method of a `Bloc` or `Cubit`. Positional and named parameters are both reported.

## Why use this rule

A `BuildContext` is only valid while its element is mounted. A Bloc typically outlives the widget that created it — it sits in a `BlocProvider` above the route, or in a `MultiBlocProvider` at the app root — so the context it was handed goes stale, and the next `Navigator.of(context)` throws from inside business logic, far from the widget that caused it.

It also makes the Bloc untestable in isolation: `blocTest` cannot supply a real context, so every test needs a widget tree.

Whatever the context was for — navigating, showing a snackbar, reading the theme — belongs in the widget, driven by the state the Bloc emits.

**See also:** [Bloc best practices](https://bloclibrary.dev/bloc-concepts/)

## Examples

### Navigating from inside the bloc

```dart
// Don't — `context` is stale by the time login finishes
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';

sealed class AuthEvent {}

class LoginRequested extends AuthEvent {}

class AuthBloc extends Bloc<AuthEvent, bool> {
  AuthBloc(this.context) : super(false) {   // LINT on `context`
    on<LoginRequested>((event, emit) async {
      emit(true);
      await Navigator.of(context).pushNamed('/home');
    });
  }

  final BuildContext context;
}
```

Emit the outcome and let the widget navigate, where the context is guaranteed live:

```dart
// Do
import 'package:bloc/bloc.dart';

sealed class AuthEvent {}

class LoginRequested extends AuthEvent {}

class AuthBloc extends Bloc<AuthEvent, bool> {
  AuthBloc() : super(false) {
    on<LoginRequested>((event, emit) => emit(true));
  }
}

// In the widget:
// BlocListener<AuthBloc, bool>(
//   listener: (context, loggedIn) {
//     if (loggedIn) Navigator.of(context).pushNamed('/home');
//   },
//   child: const LoginForm(),
// )
```

### A method parameter counts too

The context does not have to be stored — taking one at all is reported:

```dart
// Don't
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';

class SettingsCubit extends Cubit<bool> {
  SettingsCubit() : super(false);

  void applyTheme(BuildContext context) {   // LINT on `context`
    emit(MediaQuery.of(context).platformBrightness == Brightness.dark);
  }
}
```

```dart
// Do — take the value, not the context that produces it
import 'package:bloc/bloc.dart';

class SettingsCubit extends Cubit<bool> {
  SettingsCubit() : super(false);

  void applyTheme({required bool isDark}) => emit(isDark);
}

// In the widget:
// context.read<SettingsCubit>().applyTheme(
//   isDark: MediaQuery.of(context).platformBrightness == Brightness.dark,
// );
```

### Named parameters are reported

```dart
// Don't
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';

sealed class CheckoutEvent {}

class CheckoutBloc extends Bloc<CheckoutEvent, int> {
  CheckoutBloc({required BuildContext context}) : super(0);  // LINT
}
```

## Known limitations

The parameter type must be exactly `BuildContext`. A bloc that takes a wrapper carrying a context (`class NavigationService { final BuildContext context; }`) has the same lifetime hazard but no `BuildContext` parameter to match, so it is not reported.

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
