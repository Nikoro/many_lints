// avoid_build_context_in_providers
//
// Warns when a @riverpod provider takes a BuildContext parameter. Providers
// outlive the widgets that read them, so a captured context may refer to a
// widget that has already been unmounted — using it then throws, or silently
// reads stale inherited data.
//
// Note: these declarations intentionally omit the generated `_$` superclass so
// the example compiles without running build_runner.

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// ❌ Bad: A functional provider taking a BuildContext
@riverpod
// LINT: Pass the value read from the context instead
int badExample(Ref ref, BuildContext context) => 0;

// ❌ Bad: A method of an annotated class taking a BuildContext
@riverpod
class BadNotifier {
  // LINT: Same problem inside a class-based provider
  int build(BuildContext context) => 0;
}

// ✅ Good: Pass the value the provider actually needs
@riverpod
int goodExample(Ref ref, Locale locale) => 0;

// ✅ Good: No context at all
@riverpod
class GoodNotifier {
  int build() => 0;
}

// ✅ Good: An ordinary function is free to take a BuildContext
int helper(BuildContext context) => 0;
// ignore_for_file: many_lints/prefer_getter_over_method
