// provider_parameters
//
// Warns when a family provider is passed an argument with no stable equality.
// Riverpod caches one provider per family argument, keyed by ==. An argument
// that allocates a new object every build never compares equal to the previous
// one, so the provider is recreated endlessly and its state is lost.

import 'package:riverpod/riverpod.dart';

class Unstable {
  Unstable(this.id);
  final int id;
}

class Stable {
  const Stable(this.id);
  final int id;

  @override
  bool operator ==(Object other) => other is Stable && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

final listProvider = Provider.family<int, List<int>>((ref, arg) => arg.length);
final objectProvider = Provider.family<int, Object>((ref, arg) => 0);
final unstableProvider = Provider.family<int, Unstable>((ref, arg) => arg.id);
final stableProvider = Provider.family<int, Stable>((ref, arg) => arg.id);

// ❌ Bad: A new list is allocated on every build
void badList(Ref ref) {
  // LINT: Pass a const list instead
  ref.watch(listProvider([1, 2, 3]));
}

// ❌ Bad: A new closure is created on every build
void badClosure(Ref ref) {
  // LINT: Closures are never equal to one another
  ref.watch(objectProvider(() => 42));
}

// ❌ Bad: Unstable does not override ==, so each instance is distinct
void badInstance(Ref ref) {
  // LINT: Add an == override, or pass a const instance
  ref.watch(unstableProvider(Unstable(1)));
}

// ✅ Good: Const values are canonicalized, so equality holds
void goodConstList(Ref ref) {
  ref.watch(listProvider(const [1, 2, 3]));
}

// ✅ Good: A class with a real == is stable across rebuilds
void goodStableInstance(Ref ref) {
  ref.watch(stableProvider(const Stable(1)));
}
// ignore_for_file: many_lints/prefer_declaring_const_constructor
// ignore_for_file: many_lints/prefer_primary_constructors
