// ignore_for_file: unused_local_variable, unused_element

// avoid_generics_shadowing
//
// Warns when a generic type parameter shadows a top-level type declaration
// (class, mixin, enum, typedef) in the same file.

// --- Top-level types used for examples ---
class MyModel {}

class AnotherClass {}

enum MyEnum { first, second }

mixin MyMixin {}

typedef MyCallback = void Function();

// ❌ Bad: Generic type parameter shadows a top-level class
class Repository<MyModel> {
  // LINT: MyModel shadows the top-level class MyModel
  MyModel get(int id) => throw '';
}

// ❌ Bad: Method type parameter shadows a top-level enum
class SomeClass {
  void method<MyEnum>(MyEnum p) {} // LINT: MyEnum shadows the enum

  AnotherClass anotherMethod<AnotherClass>() {
    // LINT: AnotherClass shadows the class
    throw '';
  }
}

// ❌ Bad: Multiple shadowing type parameters
class BadPair<MyModel, AnotherClass> {
  // LINT: Both MyModel and AnotherClass shadow top-level types
  final MyModel first;
  final AnotherClass second;
  BadPair(this.first, this.second);
}

// ✅ Good: Use conventional single-letter type parameters
class GoodRepository<T> {
  T get(int id) => throw '';
}

// ✅ Good: Descriptive names that don't shadow top-level types
class GoodPair<TFirst, TSecond> {
  final TFirst first;
  final TSecond second;
  GoodPair(this.first, this.second);
}

// ✅ Good: No conflict when type parameter name isn't a top-level type
class Wrapper<TModel> {
  final TModel value;
  Wrapper(this.value);
}

// ✅ Good: Single-letter generics on methods
class Processor {
  void process<T>(T item) {}
  R transform<R>(Object input) => throw '';
}
