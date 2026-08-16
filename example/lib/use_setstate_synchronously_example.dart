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

  @override
  Widget build(BuildContext context) => Text('$_value');
}
