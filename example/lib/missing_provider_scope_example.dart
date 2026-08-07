// ignore_for_file: many_lints/prefer_overriding_parent_equality
// missing_provider_scope
//
// Warns when runApp() is called without a ProviderScope at the root of the
// widget tree. Riverpod stores all provider state inside a ProviderScope, so
// without one every ref.watch/ref.read throws at runtime.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ❌ Bad: No ProviderScope at the root
void badMain() {
  // LINT: Wrap the root widget in a ProviderScope
  runApp(const MyApp());
}

// ✅ Good: ProviderScope installed at the root
void goodMain() {
  runApp(const ProviderScope(child: MyApp()));
}

// ✅ Good: An externally-owned container is also a valid scope
void goodMainWithContainer() {
  final container = ProviderContainer();
  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}
