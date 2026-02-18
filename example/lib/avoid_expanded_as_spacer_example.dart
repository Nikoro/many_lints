// ignore_for_file: unused_local_variable

// avoid_expanded_as_spacer
//
// Warns when Expanded wraps an empty SizedBox or Container instead of
// using the dedicated Spacer widget.

import 'package:flutter/widgets.dart';

// ❌ Bad: Using Expanded with an empty child as a spacer
class BadExamples {
  // LINT: Expanded with empty SizedBox
  final a = const Expanded(child: SizedBox());

  // LINT: Expanded with empty Container
  final b = Expanded(child: Container());

  // LINT: Expanded with flex and empty SizedBox
  final c = const Expanded(flex: 2, child: SizedBox());
}

// ✅ Good: Using Spacer directly
class GoodExamples {
  // Use Spacer instead of Expanded + empty child
  final a = const Spacer();

  // Use Spacer with flex parameter
  final b = const Spacer(flex: 2);

  // Expanded with a non-empty child is fine
  final c = const Expanded(child: Text('content'));

  // SizedBox with dimensions is not a spacer
  final d = const Expanded(child: SizedBox(width: 10));
}
