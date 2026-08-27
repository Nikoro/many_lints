---
title: avoid_unnecessary_extends
description: "Remove an explicit `extends Object`"
sidebar:
  label: avoid_unnecessary_extends
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Code Organization</span>

Flags a class that explicitly extends `dart:core`'s `Object`.

Every Dart class extends `Object` already, so the clause states the default while looking like a decision. A reader who sees an `extends` expects the superclass to matter, and has to recall that this one does not.

This rule is in the **`opinionated`** preset, so it is on with `preset: opinionated` or `preset: pedantic`.

**See also:** [`Object`](https://api.dart.dev/stable/dart-core/Object-class.html)

## Don't

```dart
class UserRepository extends Object {
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

### A shadowing `Object` is a real superclass

The rule resolves the type rather than matching the name, so a class extending a locally declared `Object` is making a genuine choice and is left alone:

```dart
// Accepted — this `Object` is not dart:core's
class Object {
  void describe() {}
}

class Node extends Object {}
```

## Known limitations

**No quick fix.** Deleting the clause is safe, but the rename that introduced it is often mid-migration, and the author is better placed to say whether the base class is coming back.

## Turning this rule off

To disable this rule:

```yaml
# many_lints.yaml
rules:
  avoid_unnecessary_extends: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`arguments_ordering`](/many_lints/docs/rules/code-organization/arguments-ordering/) — Keep named arguments in a configured order.
- [`avoid_duplicate_mixins`](/many_lints/docs/rules/code-organization/avoid-duplicate-mixins/) — Flag a mixin applied twice in one `with` clause.
- [`avoid_generics_shadowing`](/many_lints/docs/rules/code-organization/avoid-generics-shadowing/) — Avoid generic type parameters that shadow top-level declarations.
- [`avoid_unnecessary_constructor`](/many_lints/docs/rules/code-organization/avoid-unnecessary-constructor/) — Remove a constructor identical to the default one.
