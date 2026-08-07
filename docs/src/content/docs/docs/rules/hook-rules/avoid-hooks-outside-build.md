---
title: avoid_hooks_outside_build
description: "Only call hooks from a hook context"
sidebar:
  label: avoid_hooks_outside_build
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Hook Rules</span>

This rule flags a `useX()` call that happens outside a hook context — anywhere that is not a `HookWidget.build`, a `HookBuilder`'s `builder`, or another hook function.

## Why use this rule

`flutter_hooks` stores hook state in a list attached to the element and matches each call to its slot by *position*. That bookkeeping only exists while a hook widget is building. Call a hook from an event handler, a lifecycle method, or a plain helper and there is no hook context to write into: you get an exception, or worse, state written into an unrelated widget's slots.

Together with [`avoid_conditional_hooks`](/many_lints/docs/rules/widget-best-practices/avoid-conditional-hooks/) and [`avoid_misused_hooks`](/many_lints/docs/rules/hook-rules/avoid-misused-hooks/), this covers the rules of hooks: call them unconditionally, the same number of times, from a hook context.

**See also:** [flutter_hooks rules](https://pub.dev/packages/flutter_hooks#rules)

## Don't

```dart
class MyWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // No hook context inside a callback
        final counter = useState(0);
      },
      child: const Text('tap'),
    );
  }
}
```

## Do

```dart
class MyWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // Called directly in build — valid
    final counter = useState(0);

    return ElevatedButton(
      onPressed: () => counter.value++,
      child: Text('${counter.value}'),
    );
  }
}

// Composing hooks inside another hook is valid too
ValueNotifier<int> useCounter() {
  return useState(0);
}
```

## Known limitations

Hooks are recognised by name: an unqualified call whose name matches `use` followed by an uppercase letter or digit. A hook renamed to something else is not detected, and a plain function following that naming convention is treated as a hook.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_hooks_outside_build: false
```
