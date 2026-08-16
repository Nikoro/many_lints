// ignore_for_file: many_lints/prefer_single_widget_per_file
// ignore_for_file: many_lints/prefer_overriding_parent_equality

// avoid_too_many_widgets_per_build
//
// Detects a build method creating more widgets than the configured budget.
// This example lowers the budget to 10 so the file stays readable:
//
//   avoid_too_many_widgets_per_build:
//     max_widgets: 10

import 'package:flutter/widgets.dart';

// ❌ Bad: one method owns the header, the body and the footer
class BadExample extends StatelessWidget {
  const BadExample({super.key});

  // LINT: creates more widgets than the budget, and none of them has a name
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(children: [Text('Title'), Text('Subtitle')]),
      Text('a'),
      Text('b'),
      Text('c'),
      Text('d'),
      Text('e'),
      Row(children: [Text('Cancel'), Text('Save')]),
    ],
  );
}

// ✅ Good: each part is a widget with a name, testable on its own
class GoodExample extends StatelessWidget {
  const GoodExample({super.key});

  @override
  Widget build(BuildContext context) =>
      const Column(children: [_Header(), _Body(), _Footer()]);
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) =>
      Row(children: [Text('Title'), Text('Subtitle')]);
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) =>
      Column(children: [Text('a'), Text('b'), Text('c')]);
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) =>
      Row(children: [Text('Cancel'), Text('Save')]);
}
