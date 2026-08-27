---
title: avoid_generics_shadowing
description: "Avoid generic type parameters that shadow top-level declarations."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_generics_shadowing
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Code Organization</span>

Flags a generic type parameter whose name is also a top-level declaration in the same file — a class, mixin, enum, typedef or extension type.

Inside that scope the name no longer means the class. Every annotation reading `User` looks like the model and is in fact an unbounded type parameter, so the compiler accepts a `String` where the author was certain only a `User` could arrive.

A quick fix renames the parameter to a free single letter.

This rule is in the **`recommended`** preset, so it is on with `preset: recommended`, `preset: opinionated` or `preset: pedantic`.

**See also:** [Dart language - Generics](https://dart.dev/language/generics) | [Dart lint: avoid_shadowing_type_parameters](https://dart.dev/tools/linter-rules/avoid_shadowing_type_parameters)

## Don't

```dart
class User {
  const User(this.id);

  final String id;
}

// `User` here is a type parameter, not the class above. `findById` accepts
// and returns anything at all, and nothing in the signature says so.
class Repository<User> {
  User findById(String id) => throw UnimplementedError();
}
```

## Do

```dart
class User {
  const User(this.id);

  final String id;
}

class Repository<T> {
  T findById(String id) => throw UnimplementedError();
}
```

## Examples

### A method's own type parameter shadows too

The rule looks at every type parameter list in the file, not just a class's:

```dart
enum Role { admin, guest }

class Permissions {
  // `Role` names the parameter, so `value` is unconstrained — `check(42)`
  // compiles.
  void check<Role>(Role value) {}
}
```

```dart
enum Role { admin, guest }

class Permissions {
  void check<T>(T value) {}
}
```

### Descriptive names are fine as long as they do not collide

Renaming to a single letter is what the quick fix offers, but any free name works:

```dart
class Order {}

class Invoice {}

// Reported — both parameters shadow a class in this file
class Pair<Order, Invoice> {
  Pair(this.first, this.second);

  final Order first;
  final Invoice second;
}
```

```dart
class Order {}

class Invoice {}

// Accepted — neither name is declared at the top level here
class Pair<TFirst, TSecond> {
  Pair(this.first, this.second);

  final TFirst first;
  final TSecond second;
}
```

## Known limitations

**Only declarations in the same file count.** A type parameter named after a class imported from another library is not reported — the rule reads the compilation unit's own top-level declarations, so it cannot see what an import brought in.

**Shadowing an outer *type parameter* is the SDK's job.** [`avoid_shadowing_type_parameters`](https://dart.dev/tools/linter-rules/avoid_shadowing_type_parameters) covers a method's `T` hiding its class's `T`; this rule covers a `T` hiding a real type.

**The quick fix picks the first free letter.** It skips names already used by sibling parameters, by types named in the declaring scope, and by top-level declarations, so the rename cannot reintroduce the collision — but the letter it lands on may not be the one you would have chosen.

## Configuration

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_generics_shadowing: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`arguments_ordering`](/many_lints/docs/rules/code-organization/arguments-ordering/) — Keep named arguments in a configured order.
- [`avoid_duplicate_mixins`](/many_lints/docs/rules/code-organization/avoid-duplicate-mixins/) — Flag a mixin applied twice in one `with` clause.
- [`avoid_unnecessary_constructor`](/many_lints/docs/rules/code-organization/avoid-unnecessary-constructor/) — Remove a constructor identical to the default one.
- [`avoid_unnecessary_extends`](/many_lints/docs/rules/code-organization/avoid-unnecessary-extends/) — Remove an explicit `extends Object`.
