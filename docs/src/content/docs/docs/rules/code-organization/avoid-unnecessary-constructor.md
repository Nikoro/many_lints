---
title: avoid_unnecessary_constructor
description: "Remove a constructor identical to the default one"
sidebar:
  label: avoid_unnecessary_constructor
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Code Organization</span>

Flags an empty unnamed constructor that writes out exactly what Dart supplies when no constructor is declared at all.

`class A { A(); }` has no parameters, no initializers, no body and no documentation. The line adds nothing a reader can act on, and it invites the assumption that construction does something.

This rule is in the **`opinionated`** preset, so it is on with `preset: opinionated` or `preset: pedantic`.

## Don't

```dart
class UserRepository {
  UserRepository();

  Future<void> refresh() async {}
}
```

## Do

```dart
class UserRepository {
  Future<void> refresh() async {}
}
```

## Examples

### `const` is a real difference

`const A();` lets callers write `const A()`, which the implicit constructor does not allow. It is never reported:

```dart
// Accepted — the const-ness is the point
class EmptyState {
  const EmptyState();
}

void render() {
  const state = EmptyState();
}
```

### A second constructor makes the empty one load-bearing

Dart supplies the unnamed constructor only when **no** constructor is written. Once a named one exists, deleting `A()` makes `A()` illegal:

```dart
// Accepted — removing `Duration()` would break every plain `Duration()` call
class Timeout {
  Timeout();

  Timeout.seconds(this.value);

  int value = 0;
}
```

### Documentation and annotations carry information

An empty constructor that is documented or annotated says something the implicit one cannot, so it stays:

```dart
// Accepted
class Analytics {
  /// Constructing this is cheap; the transport connects lazily.
  Analytics();
}
```

```dart
// Accepted
class Legacy {
  @Deprecated('Use Legacy.fromConfig instead.')
  Legacy();
}
```

### Named and private constructors are a different construct

Only the unnamed one duplicates a default:

```dart
// Accepted — there is no implicit `Cache._()`
class Cache {
  Cache._();

  static final instance = Cache._();
}
```

## Known limitations

**No quick fix.** Deleting the line is safe in the reported cases, but the constructor is often the anchor a diff or a code review is hanging on, and removing it silently would hide that.

## Turning this rule off

To disable this rule:

```yaml
# many_lints.yaml
rules:
  avoid_unnecessary_constructor: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`arguments_ordering`](/many_lints/docs/rules/code-organization/arguments-ordering/) — Keep named arguments in a configured order.
- [`avoid_duplicate_mixins`](/many_lints/docs/rules/code-organization/avoid-duplicate-mixins/) — Flag a mixin applied twice in one `with` clause.
- [`avoid_generics_shadowing`](/many_lints/docs/rules/code-organization/avoid-generics-shadowing/) — Avoid generic type parameters that shadow top-level declarations.
- [`avoid_unnecessary_extends`](/many_lints/docs/rules/code-organization/avoid-unnecessary-extends/) — Remove an explicit `extends Object`.
