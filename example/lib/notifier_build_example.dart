// notifier_build
//
// Warns when a class annotated with @riverpod does not define a build method.
// The generator turns `build` into the provider's create function, so without
// one the build step fails with an error pointing at the generated file rather
// than the class that caused it.
//
// Note: these classes intentionally omit the generated `_$` superclass so the
// example compiles without running build_runner.

import 'package:riverpod_annotation/riverpod_annotation.dart';

// ❌ Bad: Annotated class with no build method
@riverpod
// LINT: Add a build method
class BadCounter {}

// ❌ Bad: Has other members, but still no build method
@riverpod
// LINT: `value` is not the create function the generator looks for
class BadCounterWithGetter {
  int get value => 0;
}

// ❌ Bad: The constructor form of the annotation behaves the same
@Riverpod(keepAlive: true)
// LINT: Add a build method
class BadKeepAliveCounter {}

// ✅ Good: Defines build
@riverpod
class GoodCounter {
  int build() => 0;
}

// ✅ Good: Functional providers have no build method by design
@riverpod
int goodCounter(Ref ref) => 0;

// ✅ Good: An unannotated class is not a provider
class PlainClass {}
