import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

// avoid_unnecessary_hook_widgets
//
// HookWidget should only be used when hooks are actually called.
// If no hooks are used, use StatelessWidget instead.

// LINT: HookWidget does not use any hooks
class AvoidUnnecessaryHookWidgetsExample extends HookWidget {
  const AvoidUnnecessaryHookWidgetsExample({super.key});

  @override
  Widget build(BuildContext context) {
    // No hooks called here
    return Text('Hello');
  }
}
