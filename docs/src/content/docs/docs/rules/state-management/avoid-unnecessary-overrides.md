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

:::note[Overlaps with an SDK rule]
The SDK rule [`unnecessary_overrides`](https://dart.dev/tools/linter-rules/unnecessary_overrides) covers the **method** case. This rule extends it to getters, setters, operator overrides, and abstract redeclarations, which the SDK rule does not check.

It applies the same exemptions as the SDK rule, so an override is **not** reported when it adds a documentation comment, an annotation other than `@override` (such as `@protected` or `@Deprecated`), or a `covariant` parameter — and `noSuchMethod` is never reported. These are legitimate reasons to override a member without changing its body.

Enabling both rules means the method case is reported twice. If that bothers you, disable the SDK rule and keep this one for the wider coverage:

```yaml
# analysis_options.yaml
linter:
  rules:
    unnecessary_overrides: false
```
:::

## Why use this rule

Overrides that only delegate to `super` add visual noise without changing behavior. They make classes harder to scan and can mislead readers into thinking the override does something meaningful. Removing them keeps the codebase lean and makes intentional overrides stand out.

**See also:** [Effective Dart: Usage](https://dart.dev/effective-dart/usage) | [Dart lint: unnecessary_overrides](https://dart.dev/tools/linter-rules/unnecessary_overrides)

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

This rule is in **no preset**, so it is off unless you enable it — with
`preset: all`, or by name:

```yaml
# many_lints.yaml
rules:
  avoid_unnecessary_overrides: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  avoid_unnecessary_overrides: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
