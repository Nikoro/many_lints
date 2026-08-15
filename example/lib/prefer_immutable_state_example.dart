// ignore_for_file: unused_field
// ignore_for_file: many_lints/prefer_returning_shorthands
// ignore_for_file: many_lints/prefer_overriding_parent_equality

import 'package:flutter/widgets.dart';

// prefer_immutable_state
//
// State classes should be annotated with @immutable, so a notifier replaces
// the state object rather than mutating it — a mutation in place changes
// nothing any listener can observe.

// ❌ Bad: state classes without @immutable

// LINT: a notifier assigning to `isSubmitting` would update no listener
class BadLoginState {
  BadLoginState({this.isSubmitting = false});

  bool isSubmitting;
}

// LINT: subclasses are widened in, so this is reported too
class BadDetailedLoginState extends BadLoginState {
  BadDetailedLoginState({this.message = ''});

  String message;
}

// ✅ Good: annotated, with a const constructor and final fields
@immutable
class GoodLoginState {
  const GoodLoginState({this.isSubmitting = false});

  final bool isSubmitting;

  GoodLoginState copyWith({bool? isSubmitting}) =>
      GoodLoginState(isSubmitting: isSubmitting ?? this.isSubmitting);
}

// ✅ Good: a class that is not named as state
class LoginController {
  int attempts = 0;
}

// ✅ Edge case: a Flutter `State` is *meant* to be mutable — holding
// controllers and setState fields is its whole job — so it is excluded by
// type rather than by name.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  int _attempts = 0;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
