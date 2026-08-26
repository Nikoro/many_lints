// ignore_for_file: many_lints/prefer_single_widget_per_file
// ignore_for_file: many_lints/prefer_overriding_parent_equality

// use_setstate_synchronously
//
// Detects setState called after an await with no mounted guard. This is a
// real crash — "setState() called after dispose()" — not a style preference.

import 'package:flutter/material.dart';

class BadWidget extends StatefulWidget {
  const BadWidget({super.key});

  @override
  State<BadWidget> createState() => _BadWidgetState();
}

class _BadWidgetState extends State<BadWidget> {
  int _value = 0;

  Future<void> load() async {
    await Future<void>.delayed(Duration.zero);
    // LINT: the widget may have been disposed during the await
    setState(() => _value = 1);
  }

  @override
  Widget build(BuildContext context) => Text('$_value');
}

class GoodWidget extends StatefulWidget {
  const GoodWidget({super.key});

  @override
  State<GoodWidget> createState() => _GoodWidgetState();
}

class _GoodWidgetState extends State<GoodWidget> {
  int _value = 0;

  Future<void> load() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    setState(() => _value = 1);
  }

  // Edge case: a setState BEFORE the await crosses no async gap.
  Future<void> beforeAwait() async {
    setState(() => _value = 2);
    await Future<void>.delayed(Duration.zero);
  }

  // The wrapper form guards just as well as the early return, and is what you
  // write when there is nothing to do after the guard.
  Future<void> wrapperGuard() async {
    await Future<void>.delayed(Duration.zero);
    if (mounted) setState(() => _value = 3);
  }

  // A disjunction still returns whenever `mounted` is false, so reaching the
  // line below proves the widget is mounted.
  Future<bool> save() async => true;

  Future<void> disjunctionGuard() async {
    final succeeded = await save();
    if (!mounted || succeeded) return;

    setState(() => _value = 4);
  }

  @override
  Widget build(BuildContext context) => Text('$_value');
}
