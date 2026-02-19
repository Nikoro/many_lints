// ignore_for_file: unused_local_variable, unused_element

// avoid_ref_inside_state_dispose
//
// Warns when `ref` is accessed inside the dispose() method of a
// ConsumerState class. At disposal time, providers may already be
// disposed and accessing them can lead to unexpected errors.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final someProvider = Provider<String>((ref) => 'hello');

// ❌ Bad: Accessing ref in dispose()
class _BadExampleState extends ConsumerState<ConsumerStatefulWidget> {
  @override
  void dispose() {
    // LINT: Avoid accessing ref inside dispose
    ref.read(someProvider);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ❌ Bad: Multiple ref accesses in dispose()
class _BadExampleMultipleState extends ConsumerState<ConsumerStatefulWidget> {
  @override
  void dispose() {
    // LINT: Avoid accessing ref inside dispose
    ref.read(someProvider);
    // LINT: Avoid accessing ref inside dispose
    ref.watch(someProvider);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: No ref in dispose()
class _GoodExampleState extends ConsumerState<ConsumerStatefulWidget> {
  @override
  void dispose() {
    // Clean up without accessing ref
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ref is fine to use in build
    final value = ref.watch(someProvider);
    return Text(value);
  }
}

// ✅ Good: ref in other lifecycle methods is fine
class _GoodInitStateState extends ConsumerState<ConsumerStatefulWidget> {
  @override
  void initState() {
    super.initState();
    ref.read(someProvider);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
