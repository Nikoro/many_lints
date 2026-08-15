// ignore_for_file: unused_element

// avoid_unnecessary_extends
//
// Warns when a class explicitly extends Object, which every class does
// anyway.

// ❌ Bad: states the default
// LINT: every class extends Object
class BadRepository extends Object {}

// ✅ Good: the same class, without the clause
class GoodRepository {}

// ✅ Good: a real superclass
class Base {}

class Derived extends Base {}
