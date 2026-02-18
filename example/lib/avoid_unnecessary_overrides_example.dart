// ignore_for_file: unused_element, unused_field

// avoid_unnecessary_overrides
//
// Warns when a class or mixin overrides a member without adding
// implementation or changing the signature.

class _Base {
  void foo() {}
  void bar(int x, String y) {}
  int get value => 42;
  set value(int v) {}
  int compute(int x) => x;
}

// ❌ Bad: method overrides that only call super

class _BadMethodNoArgs extends _Base {
  @override
  void foo() {
    // LINT: only calls super.foo()
    super.foo();
  }
}

class _BadMethodExpression extends _Base {
  @override
  void foo() => super.foo(); // LINT: expression body only calls super
}

class _BadMethodWithArgs extends _Base {
  @override
  void bar(int x, String y) {
    // LINT: passes through all args unchanged
    super.bar(x, y);
  }
}

class _BadMethodWithReturn extends _Base {
  @override
  int compute(int x) => super.compute(x); // LINT: pass-through return
}

// ❌ Bad: getter/setter overrides that only delegate to super

class _BadGetter extends _Base {
  @override
  int get value => super.value; // LINT: only returns super.value
}

class _BadSetter extends _Base {
  @override
  set value(int v) => super.value = v; // LINT: only assigns super.value
}

// ❌ Bad: abstract redeclarations

abstract class _AbstractBase {
  void foo();
  int get value;
}

abstract class _BadAbstractRedeclaration extends _AbstractBase {
  @override
  void foo(); // LINT: abstract redeclaration without implementation

  @override
  int get value; // LINT: abstract getter redeclaration
}

// ❌ Bad: mixin unnecessary override

mixin _BadMixin on _Base {
  @override
  void foo() => super.foo(); // LINT
}

// ✅ Good: overrides that add actual logic

class _GoodMethodWithExtraLogic extends _Base {
  @override
  void foo() {
    print('before');
    super.foo();
  }
}

class _GoodMethodWithDifferentArgs extends _Base {
  @override
  void bar(int x, String y) {
    super.bar(x + 1, y.toUpperCase());
  }
}

class _GoodGetterWithDifferentValue extends _Base {
  @override
  int get value => super.value + 1;
}

class _GoodSetterWithExtraLogic extends _Base {
  @override
  set value(int v) {
    print('setting $v');
    super.value = v;
  }
}

// ✅ Good: empty override (intentionally suppresses behavior)
class _GoodEmptyOverride extends _Base {
  @override
  void foo() {}
}

// ✅ Good: no @override annotation
class _NoAnnotation extends _Base {
  void foo() {
    super.foo();
  }
}
