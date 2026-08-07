// ignore_for_file: unused_local_variable, unused_element, unused_field

// avoid_inherited_widget_in_initstate
//
// Warns when an InheritedWidget is looked up via .of(context) inside
// initState. The element is not fully mounted yet, so the lookup either
// throws or registers a dependency that never delivers updates.

import 'package:flutter/material.dart';

class _MyWidget extends StatefulWidget {
  const _MyWidget();

  @override
  State<_MyWidget> createState() => _BadState();
}

// ❌ Bad: inherited lookups in initState
class _BadState extends State<_MyWidget> {
  late final Color _color;
  late final double _width;

  @override
  void initState() {
    super.initState();
    // LINT: Theme.of is not valid during initState
    _color = Theme.of(context).primaryColor;
    // LINT: MediaQuery.of has the same problem
    _width = MediaQuery.of(context).size.width;
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: move the lookup to didChangeDependencies
class _GoodState extends State<_MyWidget> {
  late Color _color;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Valid here, and re-runs whenever the theme changes
    _color = Theme.of(context).primaryColor;
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: reading in build is always fine
class _GoodBuildState extends State<_MyWidget> {
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return ColoredBox(color: color);
  }
}

// ✅ Edge case: a static `of` on a plain class is not an inherited lookup
class _ServiceLocator {
  static _ServiceLocator of(BuildContext context) => _ServiceLocator();
}

class _EdgeCaseState extends State<_MyWidget> {
  @override
  void initState() {
    super.initState();
    // Not an InheritedWidget — no lint
    final locator = _ServiceLocator.of(context);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
