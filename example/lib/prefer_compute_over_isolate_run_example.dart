// ignore_for_file: unused_local_variable, avoid_print

// prefer_compute_over_isolate_run
//
// Warns when Isolate.run() is used instead of compute() for web platform
// compatibility.

import 'dart:isolate';

int _expensiveWork() => 42;

// ❌ Bad: Using Isolate.run() which is not supported on web
class BadExamples {
  Future<void> withClosure() async {
    final result = await Isolate.run(() => _expensiveWork()); // LINT
  }

  Future<void> withAsyncClosure() async {
    final result = await Isolate.run(() async => _expensiveWork()); // LINT
  }

  Future<void> withFunctionReference() async {
    final result = await Isolate.run(_expensiveWork); // LINT
  }

  Future<void> withTypeArgument() async {
    final result = await Isolate.run<int>(() => _expensiveWork()); // LINT
  }
}

// ✅ Good: Using compute() for web platform compatibility
// import 'package:flutter/foundation.dart';
class GoodExamples {
  // Future<void> withCompute() async {
  //   final result = await compute((_) => _expensiveWork(), null);
  // }
}
