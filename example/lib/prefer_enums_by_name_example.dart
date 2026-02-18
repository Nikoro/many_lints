// ignore_for_file: unused_local_variable

// prefer_enums_by_name
//
// Prefer using `.byName()` instead of `.firstWhere((e) => e.name == value)`
// on enum values. Available since Dart 2.15.

enum StyleDefinition { bold, italic, underline }

// ❌ Bad: Using firstWhere to find enum value by name
class BadExamples {
  void example() {
    // LINT: Use .byName() instead of .firstWhere()
    final style = StyleDefinition.values.firstWhere(
      (def) => def.name == 'bold',
    );

    // LINT: Reversed comparison also detected
    final style2 = StyleDefinition.values.firstWhere(
      (def) => 'italic' == def.name,
    );

    // LINT: Variable comparison
    final name = 'underline';
    final style3 = StyleDefinition.values.firstWhere((def) => def.name == name);
  }
}

// ✅ Good: Using .byName() for cleaner enum lookup
class GoodExamples {
  void example() {
    final style = StyleDefinition.values.byName('bold');

    final name = 'underline';
    final style2 = StyleDefinition.values.byName(name);
  }
}
