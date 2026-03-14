---
title: prefer_compute_over_isolate_run
description: "Use 'compute()' instead of 'Isolate.run()' for web platform compatibility."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_compute_over_isolate_run
---

| Property | Value |
|----------|-------|
| **Rule name** | `prefer_compute_over_isolate_run` |
| **Category** | Testing Rules |
| **Severity** | Warning |
| **Has quick fix** | Yes |

## Problem

Use 'compute()' instead of 'Isolate.run()' for web platform compatibility.

## Suggestion

Replace with 'compute()' from 'package:flutter/foundation.dart'.

## Example

```dart
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
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_compute_over_isolate_run: false
```
