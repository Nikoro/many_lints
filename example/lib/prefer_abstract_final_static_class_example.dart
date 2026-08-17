// prefer_abstract_final_static_class
//
// Classes with only static members should be declared as abstract final
// to prevent instantiation and inheritance.

// ❌ Bad: Static-only class without abstract final
// LINT
class BadConstants {
  static const pi = 3.14159;
  static const e = 2.71828;
}

// LINT
class BadUtils {
  static String greet(String name) => 'Hello, $name!';
  static int add(int a, int b) => a + b;
}

// ✅ Good: Static-only class declared as abstract final
abstract final class GoodConstants {
  static const pi = 3.14159;
  static const e = 2.71828;
}

abstract final class GoodUtils {
  static String greet(String name) => 'Hello, $name!';
  static int add(int a, int b) => a + b;
}

// ✅ Good: Class with instance members — not purely static
class MixedClass {
  final String name;
  MixedClass(this.name);

  static const defaultName = 'World';
}

// ✅ Good: Empty class — no members to check
class EmptyClass {}

// ❌ Bad: a private empty constructor is the older way of blocking
// instantiation — `abstract final` says the same thing and also blocks
// subclassing, so the constructor becomes dead code
// LINT
class BadPrivateConstructorGuard {
  BadPrivateConstructorGuard._();

  static const value = 42;
}

// ✅ Good: the modifiers replace the guard entirely
abstract final class GoodNoGuardNeeded {
  static const value = 42;
}

// ✅ Good: a private constructor that takes arguments is a real constructor
class WithMeaningfulPrivateConstructor {
  final int value;
  WithMeaningfulPrivateConstructor._(this.value);

  static const defaultValue = 42;
}

// ✅ Good: Class with a public constructor — not purely static
class WithConstructor {
  WithConstructor();
  static const value = 42;
}
// ignore_for_file: many_lints/avoid_unnecessary_constructor
// ignore_for_file: many_lints/member_ordering
// ignore_for_file: many_lints/prefer_declaring_const_constructor
