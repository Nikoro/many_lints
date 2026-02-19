// ignore_for_file: unused_field

// prefer_equatable_mixin
//
// Warns when a class directly extends Equatable instead of using
// EquatableMixin. Using the mixin preserves the ability to extend another
// base class while keeping all equatable features.

import 'package:equatable/equatable.dart';

// ❌ Bad: Extending Equatable directly limits class hierarchy
class BadPerson extends Equatable {
  const BadPerson(this.name, this.age);
  final String name;
  final int age;

  // LINT: Prefer using EquatableMixin instead of extending Equatable
  @override
  List<Object?> get props => [name, age];
}

// ❌ Bad: Abstract class extending Equatable
abstract class BadBaseEntity extends Equatable {
  // LINT: Prefer using EquatableMixin instead of extending Equatable
  const BadBaseEntity();
}

// ✅ Good: Using EquatableMixin preserves extends slot
class GoodPerson with EquatableMixin {
  GoodPerson(this.name, this.age);
  final String name;
  final int age;

  @override
  List<Object?> get props => [name, age];
}

// ✅ Good: Can extend another class while using EquatableMixin
class Animal {
  const Animal(this.species);
  final String species;
}

class Pet extends Animal with EquatableMixin {
  const Pet(super.species, this.name);
  final String name;

  @override
  List<Object?> get props => [species, name];
}

// ✅ Good: Abstract class using EquatableMixin
abstract class GoodBaseEntity with EquatableMixin {
  const GoodBaseEntity();
}
