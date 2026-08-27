---
title: prefer_use_prefix
description: "Custom hooks should start with the 'use' prefix."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_use_prefix
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Hook Rules</span>

This rule flags a function or method that calls a hook but is not itself named like one. A function that calls `useState`, `useMemoized`, or any other `useX()` **is** a custom hook, and must be named `useSomething` — or `_useSomething` when private.

## Why use this rule

The name is not decoration: it is how the rest of the tooling knows the call has to obey the rules of hooks. [`avoid_conditional_hooks`](/many_lints/docs/rules/widget-best-practices/avoid-conditional-hooks/), [`avoid_hooks_outside_build`](/many_lints/docs/rules/hook-rules/avoid-hooks-outside-build/) and `flutter_hooks` itself all recognise a hook by its `use` prefix. Call `_fetchData()` from inside an `if`, and nothing warns you — even though it allocates a hook slot and will corrupt the slot order.

The quick fix renames the declaration for you.

**See also:** [flutter_hooks — custom hooks](https://pub.dev/packages/flutter_hooks#custom-hooks)

## Don't

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

// A helper that calls a hook is a hook, whatever it is called.
ValueNotifier<int> counterState() {          // LINT
  return useState(0);
}

class CartPage extends HookWidget {
  const CartPage({super.key});

  // A private method is no different — it still allocates a hook slot.
  ValueNotifier<int> _quantity() {           // LINT
    return useState(1);
  }

  @override
  Widget build(BuildContext context) {
    final quantity = _quantity();
    return Text('${quantity.value}');
  }
}
```

## Do

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

ValueNotifier<int> useCounterState() {
  return useState(0);
}

class CartPage extends HookWidget {
  const CartPage({super.key});

  ValueNotifier<int> _useQuantity() {
    return useState(1);
  }

  @override
  Widget build(BuildContext context) {
    final quantity = _useQuantity();
    return Text('${quantity.value}');
  }
}
```

## Composing several hooks

The prefix matters most on a helper that bundles hooks, because that is what other code will call from inside a branch if nothing stops it:

```dart
// Don't
({ValueNotifier<String> query, TextEditingController controller}) searchState() {
  final query = useState('');
  final controller = useTextEditingController();
  return (query: query, controller: controller);
}

// Do
({ValueNotifier<String> query, TextEditingController controller})
useSearchState() {
  final query = useState('');
  final controller = useTextEditingController();
  return (query: query, controller: controller);
}
```

## Known limitations

**Nothing without a hook call is reported.** An ordinary helper keeps its ordinary name — `int subtotal() => 42;` is not a hook and is left alone.

**`@override` methods are skipped.** `build` calls hooks by design, and so may an overridden method your base class declares; renaming either is not an option, so the rule never asks.

**Hooks are recognised by name.** The check looks for a call matching `use` followed by an uppercase letter or a digit. A hook aliased to another name is not seen, and a plain function called `useTitleCase` counts as one.

**Anonymous callbacks have no name to fix.** A `HookBuilder(builder: (context) { ... })` closure is a legitimate hook context and is not reported.

## Configuration

This rule is in the **`pedantic`** preset, so it is enabled by `preset: pedantic` or by name:

```yaml
# many_lints.yaml
rules:
  prefer_use_prefix: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_use_prefix: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_use_callback`](/many_lints/docs/rules/hook-rules/prefer-use-callback/) — Use 'useCallback' instead of 'useMemoized' for memoizing functions.
- [`avoid_hooks_outside_build`](/many_lints/docs/rules/hook-rules/avoid-hooks-outside-build/) — Only call hooks from a hook context.
- [`avoid_misused_hooks`](/many_lints/docs/rules/hook-rules/avoid-misused-hooks/) — Don't call hooks inside loops.
- [`avoid_unnecessary_enum_prefix`](/many_lints/docs/rules/class-naming/avoid-unnecessary-enum-prefix/) — Drop an enum name repeated in its own constants.
