// ignore_for_file: unused_element

// avoid_default_tostring
//
// Warns when a value whose class does not override toString is
// interpolated. Object.toString renders as "Instance of 'Foo'", which is
// exactly the information the reader already had.

enum Status { active, inactive }

class _UserWithoutToString {
  const _UserWithoutToString(this.id);
  final String id;
}

class _UserWithToString {
  const _UserWithToString(this.id);
  final String id;

  @override
  String toString() => '_UserWithToString(id: $id)';
}

class _Base {
  @override
  String toString() => '_Base';
}

class _Derived extends _Base {}

// ❌ Bad: renders as "Instance of '_UserWithoutToString'"
String badInterpolation(_UserWithoutToString user) {
  // LINT: this log line says nothing useful
  return 'failed for $user';
}

// ❌ Bad: braces make no difference
String badBracedInterpolation(_UserWithoutToString user) {
  // LINT: same problem
  return 'failed for ${user}';
}

// ✅ Good: the class overrides toString
String goodOverridden(_UserWithToString user) => 'failed for $user';

// ✅ Good: toString inherited from a base class
String goodInherited(_Derived value) => 'value: $value';

// ✅ Good: interpolate the field you actually need
String goodField(_UserWithoutToString user) => 'failed for ${user.id}';

// ✅ Good: core types render usefully
String goodString(String name) => 'name: $name';

String goodInt(int count) => 'count: $count';

// ✅ Good: enums render as their constant name
String goodEnum(Status status) => 'status: $status';
// ignore_for_file: many_lints/prefer_primary_constructors
