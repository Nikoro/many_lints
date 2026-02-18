// ignore_for_file: unused_local_variable, unused_element

// prefer_overriding_parent_equality
//
// Warns when a class extends a parent that overrides == and hashCode
// but does not override them itself.

// ❌ Bad: Child inherits parent's equality without accounting for its own fields
class Parent {
  final int id;
  Parent(this.id);

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is Parent && id == other.id;
}

// LINT: Missing both == and hashCode overrides
class Child extends Parent {
  final String name;
  Child(this.name, int id) : super(id);
}

// LINT: Missing hashCode override
class ChildMissingHashCode extends Parent {
  final String name;
  ChildMissingHashCode(this.name, int id) : super(id);

  @override
  bool operator ==(Object other) =>
      other is ChildMissingHashCode && name == other.name && id == other.id;
}

// LINT: Missing == override
class ChildMissingEquals extends Parent {
  final String name;
  ChildMissingEquals(this.name, int id) : super(id);

  @override
  int get hashCode => Object.hash(id, name);
}

// ✅ Good: Child overrides both == and hashCode
class GoodChild extends Parent {
  final String name;
  GoodChild(this.name, int id) : super(id);

  @override
  int get hashCode => Object.hash(id, name);

  @override
  bool operator ==(Object other) =>
      other is GoodChild && id == other.id && name == other.name;
}

// ✅ Good: Abstract class is not flagged
abstract class AbstractChild extends Parent {
  final String label;
  AbstractChild(this.label, int id) : super(id);
}

// ✅ Good: Parent does not override equality — no warning
class SimpleParent {
  final int x;
  SimpleParent(this.x);
}

class SimpleChild extends SimpleParent {
  final int y;
  SimpleChild(this.y, int x) : super(x);
}
