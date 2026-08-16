// ignore_for_file: unused_element
// ignore_for_file: many_lints/prefer_single_widget_per_file
// ignore_for_file: many_lints/prefer_overriding_parent_equality

// prefer_widget_private_members
//
// Detects a public method or getter on a widget class.
//
// A widget's public surface is its constructor: the parameters a parent passes
// in. Everything else exists to serve `build`, and a public method invites a
// caller to invoke part of the rendering out of band.
//
// This matters more in Flutter than the general rule suggests, because a widget
// instance is rebuilt constantly — a public method sits on an object the
// framework may discard on the next frame.

import 'package:flutter/widgets.dart';

// ❌ Bad
class BadWidget extends StatelessWidget {
  const BadWidget({super.key});

  // LINT: a caller can reach in and drive part of the rendering
  void refresh() {}

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ✅ Good
class GoodWidget extends StatelessWidget {
  const GoodWidget({required this.title, super.key});

  // A widget's fields ARE its constructor parameters, so public finals are the
  // idiom the framework itself uses. Fields are never reported.
  final String title;

  void _refresh() {}

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// Edge case: a STATIC member is not reachable on a widget instance, so the
// rebuild argument does not apply to it. `static Future<T> show(context)` is
// the documented way to open a dialog or a sheet.
class GoodDialog extends StatelessWidget {
  const GoodDialog({super.key});

  static Future<void> show(BuildContext context) async {}

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
