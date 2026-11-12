// ignore_for_file: deprecated_member_use, unused_field
// ignore_for_file: many_lints/prefer_overriding_parent_equality

// prefer_equatable_mixin
//
// Warns when a class directly extends Equatable instead of mixing it in.
// Mixing it in preserves the ability to extend another base class while
// keeping all equatable features. On equatable 2.1 and later the mixin is
// Equatable itself; only 2.0 needs EquatableMixin.

import 'package:equatable/equatable.dart';

// ❌ Bad: Extending Equatable directly limits class hierarchy
class BadPerson extends Equatable {
  const BadPerson(this.name, this.age);
  final String name;
  final int age;

  // LINT: Prefer 'with Equatable' to extending Equatable
  @override
  List<Object?> get props => [name, age];
}

// ❌ Bad: Abstract class extending Equatable
abstract class BadBaseEntity extends Equatable {
  // LINT: Prefer 'with Equatable' to extending Equatable
  const BadBaseEntity();
}

// ✅ Good: Mixing in Equatable preserves extends slot
class GoodPerson with Equatable {
  GoodPerson(this.name, this.age);
  final String name;
  final int age;

  @override
  List<Object?> get props => [name, age];
}

// ✅ Good: Can extend another class while mixing in Equatable
class Animal {
  const Animal(this.species);
  final String species;
}

class Pet extends Animal with Equatable {
  const Pet(super.species, this.name);
  final String name;

  @override
  List<Object?> get props => [species, name];
}

// ✅ Good: Abstract class mixing in Equatable
abstract class GoodBaseEntity with Equatable {
  const GoodBaseEntity();
}
// ignore_for_file: many_lints/prefer_declaring_const_constructor
// ignore_for_file: many_lints/prefer_primary_constructors
