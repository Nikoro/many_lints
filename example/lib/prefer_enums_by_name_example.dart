// ignore_for_file: unused_local_variable

// prefer_enums_by_name
//
// Prefer using `.byName()` instead of `.firstWhere((e) => e.name == value)`
// on enum values. Available since Dart 2.15.

enum ShippingSpeed { standard, express, overnight }

// ❌ Bad: Using firstWhere to find enum value by name
class BadExamples {
  void example() {
    // LINT: Use .byName() instead of .firstWhere()
    final style = ShippingSpeed.values.firstWhere(
      (speed) => speed.name == 'express',
    );

    // LINT: Reversed comparison also detected
    final style2 = ShippingSpeed.values.firstWhere(
      (speed) => 'overnight' == speed.name,
    );

    // LINT: Variable comparison
    final name = 'underline';
    final style3 = ShippingSpeed.values.firstWhere(
      (speed) => speed.name == name,
    );
  }
}

// ✅ Good: Using .byName() for cleaner enum lookup
class GoodExamples {
  void example() {
    final style = ShippingSpeed.values.byName('express');

    final name = 'underline';
    final style2 = ShippingSpeed.values.byName(name);
  }
}
