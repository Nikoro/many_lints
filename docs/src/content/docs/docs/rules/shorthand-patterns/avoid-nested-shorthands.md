---
title: avoid_nested_shorthands
description: "Avoid nesting a dot shorthand inside another dot shorthand invocation."
sidebar:
  label: avoid_nested_shorthands
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Shorthand Patterns</span>

This rule flags a dot shorthand that sits inside the arguments of another dot shorthand invocation.

## Why use this rule

A shorthand drops the type name on the promise that context makes it obvious. That holds for the outermost one — its type comes from the variable or parameter right next to it. It breaks for the inner ones: their types come from the *outer constructor's signature*, which is not on the screen, so the reader has to go look up each parameter's declared type to find out what is being built.

The report lands on the **nested** shorthand, not the outer one, so the fix stays local: name the inner type and the outer shorthand keeps its brevity.

**See also:** [Dart language — dot shorthands](https://dart.dev/language/dot-shorthands)

## Don't

```dart
class Duration_ {
  const Duration_(this.seconds);

  final int seconds;

  static const Duration_ instant = Duration_(0);
}

class Animation {
  const Animation({required this.duration});

  final Duration_ duration;
}

class Transition {
  const Transition(this.animation);
}

void build() {
  // Nothing here names a type — the reader cannot tell what is being built.
  final Transition fade = .new(.new(duration: .new(300)));   // LINT x2

  final Transition instant = .new(.new(duration: .instant)); // LINT x2
}
```

## Do

Name the inner types; the outer shorthand still drops `Transition`:

```dart
void build() {
  final Transition fade = .new(Animation(duration: Duration_(300)));

  final Transition instant = .new(Animation(duration: Duration_.instant));
}
```

Naming the outer type instead works just as well, as long as only one level of
shorthand remains:

```dart
void build() {
  final fade = Transition(.new(duration: Duration_(300)));
}
```

## What is and is not "nested"

### Siblings are fine

Two shorthands in the same statement, neither inside the other, are not reported:

```dart
void build() {
  final Duration_ quick = .instant;
  final Animation slide = .new(duration: Duration_(300));
}
```

### A shorthand as the only argument of an explicit call is fine

```dart
// Not reported — `Animation(...)` names the outer type
void build() {
  final slide = Animation(duration: .instant);
}
```

### Depth does not save it

The search is deep, so a shorthand buried inside a sub-expression of the outer
shorthand's arguments still counts, even when its direct parent names a type:

```dart
// Reported: `.instant` is inside the outer `.new(...)` argument list
void build() {
  final Transition fade = .new(Animation(duration: .instant));
}

// Do
void build() {
  final Transition fade = .new(Animation(duration: Duration_.instant));
}
```

## Known limitations

**All three shorthand forms count**, as either the outer or the inner node where the syntax allows: constructor invocations (`.new(...)`), static method invocations (`.make(...)`), and property accesses (`.zero`). A property access has no argument list, so it can only ever be the nested one.

**Closures are not a boundary.** A shorthand inside a callback passed as an argument still resolves against the enclosing invocation's parameter type, so it reads just as poorly and is reported.

## Configuration

This rule appears only in the **`pedantic`** preset, because compact nested
shorthands are a readability choice on which coherent codebases disagree.

```yaml
# many_lints.yaml
rules:
  avoid_nested_shorthands: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  avoid_nested_shorthands: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_returning_shorthands`](/many_lints/docs/rules/shorthand-patterns/prefer-returning-shorthands/) — Use dot shorthand constructors in expression function return values.
- [`prefer_shorthands_with_constructors`](/many_lints/docs/rules/shorthand-patterns/prefer-shorthands-with-constructors/) — Use dot shorthand constructors for common Flutter classes.
- [`prefer_shorthands_with_enums`](/many_lints/docs/rules/shorthand-patterns/prefer-shorthands-with-enums/) — Use dot shorthands instead of explicit enum prefixes.
- [`prefer_shorthands_with_static_fields`](/many_lints/docs/rules/shorthand-patterns/prefer-shorthands-with-static-fields/) — Use dot shorthands instead of explicit class prefixes for static fields.
