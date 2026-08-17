// ignore_for_file: unused_element, unused_local_variable

// avoid_unrelated_type_casts
//
// Warns about `as` casts and `is` checks between types with no possible
// common subtype. The cast can only throw, and the check can only be false —
// so the guarded branch is dead code that looks live.

enum Color { red }

enum Size { big }

class Animal {}

class Dog extends Animal {}

final class ClosedFoo {}

final class ClosedBar {}

// ❌ Bad: unrelated core types
int badCoreCast(String value) {
  // LINT: a String is never an int, so this always throws
  return value as int;
}

// ❌ Bad: an `is` check that can never be true
bool badCoreCheck(String value) {
  // LINT: always false, so any guarded branch is unreachable
  return value is int;
}

// ❌ Bad: two different enums
Size badEnumCast(Color value) {
  // LINT: enums are closed, so nothing implements both
  return value as Size;
}

// ❌ Bad: final classes cannot gain a shared subtype
ClosedBar badFinalCast(ClosedFoo value) {
  // LINT: `final` closes both types to outside implementations
  return value as ClosedBar;
}

// ✅ Good: a downcast inside one hierarchy
Dog goodDowncast(Animal value) => value as Dog;

// ✅ Good: an upcast inside one hierarchy
Animal goodUpcast(Dog value) => value as Animal;

// ✅ Good: narrowing an untyped value is the normal use of `as`
int goodFromDynamic(dynamic value) => value as int;

// ✅ Good: `Object` really might hold an int
bool goodFromObject(Object value) => value is int;

// ✅ Edge case: nullability alone is not an unrelated-type problem
String nullabilityOnly(String? value) => value as String;

// ✅ Edge case: two open classes could share a subtype, so this is legal
class OpenFoo {}

class OpenBar {}

class Both implements OpenFoo, OpenBar {}

OpenBar openClassesAreAllowed(OpenFoo value) => value as OpenBar;

// ✅ Edge case: a type parameter's real argument is unknown here
T fromTypeParameter<T>(Object value) => value as T;
// ignore_for_file: many_lints/prefer_boolean_prefixes
