// ignore_for_file: unused_element, unused_local_variable

// avoid_shadowed_extension_methods
//
// Warns when an extension declares a member the extended type already has.
// Instance members always win over extension members, so the extension one is
// never called — the code reads as if it applies and behaves as if it does not.

class Model {
  int get id => 1;

  void save() {}
}

class Base {
  void reset() {}
}

class Derived extends Base {}

// ❌ Bad: String already declares toUpperCase
extension BadStringExtension on String {
  // LINT: String.toUpperCase always wins
  String toUpperCase() => '!';
}

// ❌ Bad: shadowing a user-declared method
extension BadModelExtension on Model {
  // LINT: Model.save always wins
  void save() {}
}

// ❌ Bad: shadowing a getter counts too
extension BadGetterExtension on Model {
  // LINT: Model.id always wins
  int get id => 2;
}

// ❌ Bad: an inherited member shadows just the same
extension BadInheritedExtension on Derived {
  // LINT: Base.reset is inherited by Derived
  void reset() {}
}

// ✅ Good: a name the type does not already use
extension GoodStringExtension on String {
  String shout() => '$this!';
}

// ✅ Good: a distinct getter name
extension GoodGetterExtension on Model {
  bool get isPersisted => id > 0;
}

// ✅ Edge case: static members are reached through the extension name
extension StaticExtension on Model {
  static void save() {}
}

// ✅ Edge case: Object members are excluded, or every extension would report
extension DescribeExtension on Model {
  String describe() => 'model';
}
