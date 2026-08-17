// ignore_for_file: unused_element

import 'dart:async';

// prefer_correct_future_return_type
//
// Async declarations should expose a non-nullable Future return type.

// ❌ Bad: async results are hidden behind broad or nullable types.
// LINT: callers cannot see that this always returns a Future.
Object badObjectReturn() async => 1;

// LINT: an async declaration never returns synchronously.
FutureOr<int> badFutureOrReturn() async => 1;

// LINT: the Future object itself cannot be null.
Future<int>? badNullableFutureReturn() async => 1;

// ✅ Good: the asynchronous contract is explicit.
Future<Object> goodObjectReturn() async => 1;

Future<int> goodFutureReturn() async => 1;

// ✅ Good: void is intentional for fire-and-forget callback APIs.
void goodEventHandler() async {}
