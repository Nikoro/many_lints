---
title: avoid_duplicate_mixins
description: "Flag a mixin applied twice in one `with` clause"
sidebar:
  label: avoid_duplicate_mixins
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Code Organization</span>

Flags a `with` clause that lists the same mixin more than once.

`class A with M, M {}` compiles, and the second `M` adds no members — they are already there. What it does add is a false signal: a reader counting the behaviours mixed into `A` sees one more than exists, and has to check whether the two entries differ before concluding they do not.

Duplicates arrive through merges, and through a rename that collapses two once-distinct names onto one.

This rule is in the **`recommended`** preset, so it is on with `preset: recommended`, `preset: opinionated` or `preset: pedantic`.

**See also:** [Mixins](https://dart.dev/language/mixins)

## Don't

```dart
mixin Loggable {}

mixin Cacheable {}

class Report with Loggable, Cacheable, Loggable {}
```

## Do

```dart
mixin Loggable {}

mixin Cacheable {}

class Report with Loggable, Cacheable {}
```

## Examples

### An import alias is still the same mixin

The comparison is on resolved types, not on the text you wrote, so aliasing does not hide a duplicate:

```dart
// analytics.dart
import 'package:my_app/tracking.dart';
import 'package:my_app/tracking.dart' as tracking;

class Session with Trackable, tracking.Trackable {}
```

Drop one of the two:

```dart
import 'package:my_app/tracking.dart';

class Session with Trackable {}
```

### Different type arguments are different mixins

Type arguments are kept, so a genuinely distinct instantiation is not reported:

```dart
mixin Serializes<T> {}

// Accepted — two different instantiations
class Envelope with Serializes<int>, Serializes<String> {}

// Reported — the same one twice
class Payload with Serializes<int>, Serializes<int> {}
```

### Enums and class type aliases are checked too

Any `with` clause counts, not just a class's:

```dart
mixin Describable {}

// Reported — an enum's with clause
enum Status with Describable, Describable { open, closed }

// Reported — a class type alias
class Base {}

class Composed = Base with Describable, Describable;
```

## Known limitations

**Re-applying a mixin a superclass already has is not reported.** That is a different question and it is not inert: repeating a mixin further down changes the linearization order, so which override wins can genuinely change.

```dart
mixin Loggable {}

class Base with Loggable {}

// Not reported — this re-application moves Loggable in the chain
class Report extends Base with Loggable {}
```

**Each `with` clause is compared on its own.** A mixin listed on a class and again on a different class in the same file is two clauses, not a duplicate.

**No quick fix.** Removing an entry is safe for a plain duplicate, but the two spellings may differ in ways only the author can judge — an alias may be a leftover from a migration that is not finished.

## Turning this rule off

To disable this rule:

```yaml
# many_lints.yaml
rules:
  avoid_duplicate_mixins: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`arguments_ordering`](/many_lints/docs/rules/code-organization/arguments-ordering/) — Keep named arguments in a configured order.
- [`avoid_generics_shadowing`](/many_lints/docs/rules/code-organization/avoid-generics-shadowing/) — Avoid generic type parameters that shadow top-level declarations.
- [`avoid_unnecessary_constructor`](/many_lints/docs/rules/code-organization/avoid-unnecessary-constructor/) — Remove a constructor identical to the default one.
- [`avoid_unnecessary_extends`](/many_lints/docs/rules/code-organization/avoid-unnecessary-extends/) — Remove an explicit `extends Object`.
