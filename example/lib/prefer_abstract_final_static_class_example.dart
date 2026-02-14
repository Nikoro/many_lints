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

// ✅ Good: Class with a constructor — not purely static
class WithConstructor {
  WithConstructor._();
  static const value = 42;
}
