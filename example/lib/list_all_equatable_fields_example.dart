// ignore_for_file: unused_field

// list_all_equatable_fields
//
// Warns when a class extending Equatable or using EquatableMixin does not
// include all of its declared instance fields in the props getter.

import 'package:equatable/equatable.dart';

// ❌ Bad: Missing 'age' from props
class BadPerson extends Equatable {
  const BadPerson(this.name, this.age);
  final String name;
  final int age;

  // LINT: 'age' is declared but not listed in props
  @override
  List<Object?> get props => [name];
}

// ❌ Bad: Missing all fields from props
class BadEmpty extends Equatable {
  const BadEmpty(this.x, this.y);
  final double x;
  final double y;

  // LINT: 'x' and 'y' are declared but not listed in props
  @override
  List<Object?> get props => [];
}

// ❌ Bad: Using EquatableMixin with missing field
class BadMixinPerson with EquatableMixin {
  BadMixinPerson(this.name, this.email);
  final String name;
  final String email;

  // LINT: 'email' is declared but not listed in props
  @override
  List<Object?> get props => [name];
}

// ✅ Good: All fields are listed in props
class GoodPerson extends Equatable {
  const GoodPerson(this.name, this.age);
  final String name;
  final int age;

  @override
  List<Object?> get props => [name, age];
}

// ✅ Good: All fields listed with EquatableMixin
class GoodMixinPerson with EquatableMixin {
  GoodMixinPerson(this.name, this.email);
  final String name;
  final String email;

  @override
  List<Object?> get props => [name, email];
}

// ✅ Good: Static fields are correctly excluded
class PersonWithStatic extends Equatable {
  const PersonWithStatic(this.name);
  final String name;
  static const maxNameLength = 100;

  @override
  List<Object?> get props => [name];
}

// ✅ Good: No fields means empty props is fine
class EmptyEquatable extends Equatable {
  const EmptyEquatable();

  @override
  List<Object?> get props => [];
}
