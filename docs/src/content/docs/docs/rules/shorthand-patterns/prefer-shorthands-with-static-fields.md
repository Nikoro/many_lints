---
title: prefer_shorthands_with_static_fields
description: "Use dot shorthands instead of explicit class prefixes for static fields."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_shorthands_with_static_fields
---

<span class="rule-badge rule-badge--version">v0.3.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Shorthand Patterns</span>

This rule flags `Currency.usd` where the expected type is already `Currency`, because `.usd` says the same thing.

It applies wherever the context supplies the type: switch cases and switch expression patterns, typed variable declarations, `==` comparisons, default parameter values, and returns from a function with a declared return type.

Enums have their own rule — [`prefer_shorthands_with_enums`](/many_lints/docs/rules/shorthand-patterns/prefer-shorthands-with-enums/). This one is for value classes with `static const` instances.

**See also:** [Dart language — dot shorthands](https://dart.dev/language/dot-shorthands)

## Don't

```dart
class Currency {
  const Currency(this.code);

  final String code;

  static const usd = Currency('USD');
  static const eur = Currency('EUR');
}

void example(Currency? selected) {
  switch (selected) {
    case Currency.usd:            // LINT
      print('dollars');
    default:
      break;
  }

  final Currency fallback = Currency.eur;   // LINT

  if (selected == Currency.usd) {}          // LINT
}
```

## Do

```dart
void example(Currency? selected) {
  switch (selected) {
    case .usd:
      print('dollars');
    default:
      break;
  }

  final Currency fallback = .eur;

  if (selected == .usd) {}
}
```

## More places the context supplies the type

### A default parameter value

```dart
// Don't
void price(double amount, {Currency in_ = Currency.usd}) {}

// Do
void price(double amount, {Currency in_ = .usd}) {}
```

### A declared return type

Both the arrow body and an explicit `return` are reported:

```dart
// Don't
Currency preferred() => Currency.usd;

Currency preferredOrDefault(Currency? chosen) {
  return chosen ?? Currency.eur;
}

// Do
Currency preferred() => .usd;

Currency preferredOrDefault(Currency? chosen) {
  return chosen ?? .eur;
}
```

### A switch expression pattern

```dart
// Don't
final symbol = switch (selected) {
  Currency.usd => r'$',
  Currency.eur => '€',
  _ => '?',
};

// Do
final symbol = switch (selected) {
  .usd => r'$',
  .eur => '€',
  _ => '?',
};
```

## Known limitations

Keeping the class name is correct — and the rule stays silent — when the shorthand would not compile or would mean something else:

**No context type.** `Object getObject() => Currency.usd;` is not reported: the expected type is `Object`, so `.usd` has nothing to resolve against.

**The field's type differs from its class.** `static const String staticString = 'test'` on `Currency` is a `String`, not a `Currency`, so `Currency.staticString` is left alone.

**Access through an import prefix.** `prefix.Currency.usd` is skipped, since the leading name is the library prefix rather than the class.

**A generic type argument inferred from the argument.** In `Box(items: const [Currency.usd])` the analyzer solves `T` *from* the element, so there is no downward context and `.usd` would fail to compile. Writing `Box<Currency>(items: const [.usd])` gives a real context type and is reported.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_shorthands_with_static_fields: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_shorthands_with_static_fields: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_nested_shorthands`](/many_lints/docs/rules/shorthand-patterns/avoid-nested-shorthands/) — Avoid nesting a dot shorthand inside another dot shorthand invocation.
- [`prefer_returning_shorthands`](/many_lints/docs/rules/shorthand-patterns/prefer-returning-shorthands/) — Use dot shorthand constructors in expression function return values.
- [`prefer_shorthands_with_constructors`](/many_lints/docs/rules/shorthand-patterns/prefer-shorthands-with-constructors/) — Use dot shorthand constructors for common Flutter classes.
- [`prefer_shorthands_with_enums`](/many_lints/docs/rules/shorthand-patterns/prefer-shorthands-with-enums/) — Use dot shorthands instead of explicit enum prefixes.
