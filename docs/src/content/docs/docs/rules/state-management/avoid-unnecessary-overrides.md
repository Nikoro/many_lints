---
title: avoid_unnecessary_overrides
description: "Detect overrides that only delegate to super"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_unnecessary_overrides
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">State Management</span>

Warns when a class or mixin overrides a method, getter, or setter without adding any logic beyond calling `super`. This includes pass-through methods that forward all arguments unchanged, getters that only return `super.getter`, setters that only assign `super.setter`, and abstract redeclarations.

## Why use this rule

Overrides that only delegate to `super` add visual noise without changing behavior. They make classes harder to scan and can mislead readers into thinking the override does something meaningful. Removing them keeps the codebase lean and makes intentional overrides stand out.

**See also:** [Effective Dart: Usage](https://dart.dev/effective-dart/usage)

## Don't

```dart
class _Base {
  void foo() {}
  void bar(int x, String y) {}
  int get value => 42;
  set value(int v) {}
  int compute(int x) => x;
}

class _BadMethodNoArgs extends _Base {
  @override
  void foo() {
    super.foo();
  }
}

class _BadMethodWithArgs extends _Base {
  @override
  void bar(int x, String y) {
    super.bar(x, y);
  }
}

class _BadGetter extends _Base {
  @override
  int get value => super.value;
}

class _BadSetter extends _Base {
  @override
  set value(int v) => super.value = v;
}

abstract class _AbstractBase {
  void foo();
}

abstract class _BadAbstractRedeclaration extends _AbstractBase {
  @override
  void foo(); // Abstract redeclaration without implementation
}
```

## Do

```dart
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

// Empty override intentionally suppresses behavior
class _GoodEmptyOverride extends _Base {
  @override
  void foo() {}
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_unnecessary_overrides: false
```
