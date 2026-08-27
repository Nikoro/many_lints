---
title: prefer_immediate_return
description: "Return an expression directly instead of via a throwaway variable"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_immediate_return
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Code Quality</span>

This rule flags a local variable that is declared and then returned on the very next line, with no other use.

## Why use this rule

The variable adds a name but no information — the return statement already says what the value is for. It also adds a line that has to be kept in sync: rename the variable and two places change instead of none.

## Don't

```dart
class Cart {
  const Cart(this.lines);
  final List<CartLine> lines;

  int subtotal() {
    final total = lines.fold(0, (sum, line) => sum + line.amount);
    return total;
  }
}

class CartLine {
  const CartLine(this.amount);
  final int amount;
}
```

## Do

```dart
class Cart {
  const Cart(this.lines);
  final List<CartLine> lines;

  int subtotal() {
    return lines.fold(0, (sum, line) => sum + line.amount);
  }
}

class CartLine {
  const CartLine(this.amount);
  final int amount;
}
```

### In an `async` method, keep the `await`

The rule reports the same shape inside an `async` body. Inline the initializer *with* its `await` — dropping it leaves an `async` method with no `await`, which [`avoid_redundant_async`](/many_lints/docs/rules/async-safety/avoid-redundant-async/) then reports, and both rules are in `opinionated`:

```dart
class Api {
  Future<String> fetchUser(String id) async => id;
}

class Screen {
  Screen(this.api);

  final Api api;

  // Don't
  Future<String> loadBad(String id) async {
    final user = await api.fetchUser(id);
    return user;
  }

  // Do
  Future<String> loadGood(String id) async {
    return await api.fetchUser(id);
  }
}
```

## Known limitations

The rule reports only when the variable is provably throwaway:

- It is the second-to-last statement, directly followed by `return name;`.
- The declaration declares exactly one variable — `var a = 1, b = 2;` is skipped.
- It has an initializer and is not `late`.
- The returned identifier resolves to that declaration, not a field or outer variable with the same name.
- The variable is referenced exactly once in the whole function body — the return itself.

A variable kept deliberately as documentation (`final isEligible = ...; return isEligible;`) will be reported. If the name earns its place, suppress the diagnostic on that line.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_immediate_return: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_immediate_return: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_early_return`](/many_lints/docs/rules/control-flow/prefer-early-return/) — Replace a body-wrapping if with an early-return guard.
- [`avoid_collapsible_if`](/many_lints/docs/rules/control-flow/avoid-collapsible-if/) — Merge nested if statements with &amp;&amp;.
- [`avoid_redundant_else`](/many_lints/docs/rules/control-flow/avoid-redundant-else/) — Drop the else when the if branch always exits.
- [`avoid_accessing_other_classes_private_members`](/many_lints/docs/rules/code-quality/avoid-accessing-other-classes-private-members/) — Make the underscore mean what everyone reads it as.
