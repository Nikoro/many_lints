// ignore_for_file: unused_element, unused_local_variable
// ignore_for_file: many_lints/function_always_returns_null

/// Examples of the `prefer_type_over_var` lint rule.

// ❌ Bad: Using var instead of explicit type
class BadExamples {
  void method() {
    var nickname = lookupNickname(); // LINT: Prefer explicit type
    var anotherVar = 'string'; // LINT: Prefer explicit type
    var number = 42; // LINT: Prefer explicit type
    var list = [1, 2, 3]; // LINT: Prefer explicit type
  }

  void forLoopExample() {
    for (var i = 0; i < 10; i++) {
      // LINT: Prefer explicit type
      print(i);
    }
  }
}

// LINT: Prefer explicit type
var badTopLevelVariable = lookupNickname();

String? lookupNickname() => null;

// ✅ Good: Using explicit types
class GoodExamples {
  void method() {
    String? nickname = lookupNickname();
    String anotherVar = 'string';
    int number = 42;
    List<int> list = [1, 2, 3];
  }

  void forLoopExample() {
    for (int i = 0; i < 10; i++) {
      print(i);
    }
  }
}

String? goodTopLevelVariable = lookupNickname();

// ✅ Good: Using final for type inference (when appropriate)
class FinalExamples {
  void method() {
    final nickname = lookupNickname(); // OK: final with inference
    final anotherVar = 'string'; // OK: final with inference
    final number = 42; // OK: final with inference
  }
}

final okTopLevelFinal = lookupNickname();

// ✅ Good: Using const for compile-time constants
class ConstExamples {
  void method() {
    const number = 42; // OK: const with inference
    const text = 'hello'; // OK: const with inference
  }
}

const okTopLevelConst = 'constant';

// Use case examples

class UseCase {
  // When the type might not be obvious from the initializer
  void notObviousType() {
    // ❌ Bad: Type not clear from initializer
    var result = processData(); // LINT

    // ✅ Good: Type is explicit
    Map<String, dynamic> result2 = processData();
  }

  // When dealing with nullable types
  void nullableTypes() {
    // ❌ Bad: Nullability not obvious
    var maybeNull = lookupNickname(); // LINT

    // ✅ Good: Nullability is clear
    String? maybeNull2 = lookupNickname();
  }

  Map<String, dynamic> processData() => {};
}
