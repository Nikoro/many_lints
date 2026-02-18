// ignore_for_file: unused_element, unused_field

// avoid_unnecessary_overrides_in_state
//
// Warns when a State class contains method overrides that only call the
// super implementation without any additional logic.

import 'package:flutter/material.dart';

// ❌ Bad: Overrides that only call super
class _BadWidget extends StatefulWidget {
  const _BadWidget();

  @override
  State<_BadWidget> createState() => _BadWidgetState();
}

class _BadWidgetState extends State<_BadWidget> {
  // LINT: dispose only calls super.dispose()
  @override
  void dispose() {
    super.dispose();
  }

  // LINT: initState only calls super.initState()
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ❌ Bad: Expression body that only calls super
class _BadExpressionWidget extends StatefulWidget {
  const _BadExpressionWidget();

  @override
  State<_BadExpressionWidget> createState() => _BadExpressionWidgetState();
}

class _BadExpressionWidgetState extends State<_BadExpressionWidget> {
  // LINT: initState uses expression body to just call super
  @override
  void initState() => super.initState();

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: Overrides that include additional logic
class _GoodWidget extends StatefulWidget {
  const _GoodWidget();

  @override
  State<_GoodWidget> createState() => _GoodWidgetState();
}

class _GoodWidgetState extends State<_GoodWidget> {
  final ValueNotifier<int> _counter = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _counter.addListener(_onChanged);
  }

  @override
  void dispose() {
    _counter.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: No overrides at all
class _MinimalWidget extends StatefulWidget {
  const _MinimalWidget();

  @override
  State<_MinimalWidget> createState() => _MinimalWidgetState();
}

class _MinimalWidgetState extends State<_MinimalWidget> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}
