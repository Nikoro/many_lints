// ignore_for_file: avoid_print
// ignore_for_file: many_lints/prefer_single_widget_per_file
// ignore_for_file: many_lints/prefer_overriding_parent_equality
// ignore_for_file: many_lints/prefer_correct_handler_name

// prefer_extracting_callbacks
//
// Detects a long inline closure passed as a widget's callback.
//
//   prefer_extracting_callbacks:
//     max_statements: 3
//     ignored_parameters: [builder, itemBuilder, separatorBuilder]

import 'package:flutter/material.dart';

class BadExample extends StatelessWidget {
  const BadExample({super.key});

  // ❌ Bad
  // LINT: logic sits in the middle of a layout description, is read by anyone
  // scanning for the tree's shape, and is re-created on every rebuild.
  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: () {
      print('validating');
      print('saving');
      print('closing');
      print('done');
    },
    child: const Text('Save'),
  );
}

class GoodExample extends StatelessWidget {
  const GoodExample({super.key});

  void _save() {
    print('validating');
    print('saving');
    print('closing');
    print('done');
  }

  // ✅ Good: the tree stays readable and the behaviour has a name.
  @override
  Widget build(BuildContext context) =>
      ElevatedButton(onPressed: _save, child: const Text('Save'));
}

class ShortCallbackExample extends StatelessWidget {
  const ShortCallbackExample({super.key});

  // Edge case: a short closure is a tear-off in all but spelling, so it stays
  // below `max_statements` and is never reported.
  @override
  Widget build(BuildContext context) =>
      ElevatedButton(onPressed: () => print('save'), child: const Text('Save'));
}

class BuilderExample extends StatelessWidget {
  const BuilderExample({super.key});

  // Edge case: a `builder` describes a SUBTREE rather than attaching behaviour,
  // so it is exempt — extracting it would trip `avoid_returning_widgets`.
  @override
  Widget build(BuildContext context) => Builder(
    builder: (context) {
      final theme = Theme.of(context);
      final color = theme.primaryColor;
      final text = color.toString();
      return Text(text);
    },
  );
}
