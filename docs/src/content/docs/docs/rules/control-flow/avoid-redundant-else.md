---
title: avoid_redundant_else
description: "Drop the else when the if branch always exits"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_redundant_else
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

This rule flags an `else` branch whose matching `if` branch always exits — via `return`, `throw`, `break`, or `continue`.

## Why use this rule

When the then-branch cannot fall through, the `else` adds nothing: control reaching the code after the `if` already implies the condition was false. What it does add is a level of indentation for everything that follows, which compounds in methods with several guards.

Removing it produces the guard-clause style: handle the exceptional cases early and let the main path stay flat.

## Don't

```dart
String describe(int value) {
  if (value < 0) {
    return 'negative';
  } else {
    // Indented for no reason — the branch above always returns
    return 'non-negative';
  }
}
```

## Do

```dart
String describe(int value) {
  if (value < 0) {
    return 'negative';
  }
  return 'non-negative';
}
```

## Known limitations

`else if` chains are never reported. They read as a single decision, and splitting them into sequential `if` statements usually reads worse than the chain.

The exit check is syntactic: a branch counts as exiting when its last statement is a `return`, `throw`, `break`, or `continue`. A branch that exits through a helper (`_fail()` returning `Never`) is not recognised.

The quick fix declines to hoist an `else` body that declares a variable, since the name could collide in the enclosing scope. Those cases report without an automatic fix.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_redundant_else: false
```
