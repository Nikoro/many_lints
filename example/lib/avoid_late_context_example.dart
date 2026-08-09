// ignore_for_file: unused_local_variable, unused_element, unused_field
// ignore_for_file: many_lints/prefer_overriding_parent_equality, many_lints/prefer_immutable_bloc_state, many_lints/avoid_unnecessary_stateful_widgets, many_lints/prefer_returning_shorthands, many_lints/use_dedicated_media_query_methods, many_lints/avoid_default_tostring

// avoid_late_context
//
// Warns when a `late` field inside a State reads `context` in its
// initializer. A `late` field initializes exactly once, at an unpredictable
// moment, so the value freezes and later theme/media changes are ignored.

import 'package:flutter/material.dart';

class _MyWidget extends StatefulWidget {
  const _MyWidget();

  @override
  State<_MyWidget> createState() => _BadState();
}

// ❌ Bad: the value is captured once and never refreshed
class _BadState extends State<_MyWidget> {
  // LINT: frozen at first access, and may run before the widget is mounted
  late final theme = Theme.of(context);

  @override
  Widget build(BuildContext context) => Text('${theme.hashCode}');
}

// ❌ Bad: reading through the context is the same problem
class _BadIndirectState extends State<_MyWidget> {
  // LINT: a derived value goes just as stale
  late final textScale = MediaQuery.of(context).textScaler;

  @override
  Widget build(BuildContext context) => Text('$textScale');
}

// ✅ Good: read in build, so it re-reads on every rebuild
class _GoodBuildState extends State<_MyWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text('${theme.hashCode}');
  }
}

// ✅ Good: cache in didChangeDependencies, which Flutter calls again when an
// inherited dependency changes
class _GoodCachedState extends State<_MyWidget> {
  late ThemeData _theme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
  }

  @override
  Widget build(BuildContext context) => Text('${_theme.hashCode}');
}

// ✅ Good: a late field that does not touch context is fine
class _GoodPlainState extends State<_MyWidget> {
  late final int value = 42;

  @override
  Widget build(BuildContext context) => Text('$value');
}

// ✅ Edge case: a late field with no initializer is assigned explicitly
class _GoodDeclaredState extends State<_MyWidget> {
  late final ThemeData theme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  @override
  Widget build(BuildContext context) => Text('${theme.hashCode}');
}
