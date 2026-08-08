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
Future<User> loadUser(String id) async {
  final user = await repository.fetchUser(id);
  return user;
}
```

## Do

```dart
Future<User> loadUser(String id) async {
  return repository.fetchUser(id);
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

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_immediate_return: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
