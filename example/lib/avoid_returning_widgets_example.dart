// ignore_for_file: unused_element

// avoid_returning_widgets
//
// Warns when a function, method, or getter returns a Widget or Widget subclass.
// Extracting widgets into helper methods is a Flutter anti-pattern because
// the framework cannot optimize rebuilds. Extract into separate widget classes.

import 'package:flutter/widgets.dart';

// ❌ Bad: Returning widgets from methods/functions/getters
class BadExamples extends StatelessWidget {
  const BadExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [_buildHeader(), _body, buildFooter()]);
  }

  // LINT: Method returning a widget
  Widget _buildHeader() {
    return const Text('Header');
  }

  // LINT: Getter returning a widget
  Widget get _body => const Text('Body');

  // LINT: Static method returning a widget
  static Widget buildFooter() {
    return const Text('Footer');
  }
}

// LINT: Top-level function returning a widget
Widget buildGreeting() {
  return const Text('Hello');
}

// ✅ Good: Extract widgets into separate classes
class GoodExamples extends StatelessWidget {
  const GoodExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(children: [_Header(), _Body(), _Footer()]);
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => const Text('Header');
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) => const Text('Body');
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => const Text('Footer');
}

// ✅ Good: Methods returning non-widget types are fine
class Helpers {
  String getName() => 'hello';
  int getCount() => 42;
}
