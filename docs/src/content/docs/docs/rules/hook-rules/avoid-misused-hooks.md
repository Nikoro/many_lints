---
title: avoid_misused_hooks
description: "Don't call hooks inside loops"
sidebar:
  label: avoid_misused_hooks
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Hook Rules</span>

This rule flags a `useX()` call inside a `for`, `for-in`, `while`, or `do-while` loop, including the `for` element inside a collection literal.

## Why use this rule

Hook state is addressed by call position. A hook inside a loop runs as many times as the loop iterates, so the number of hook calls depends on your data. The moment that data changes length, every hook after the loop shifts to a different slot and starts reading state that belongs to another hook.

The symptom is state that appears to jump between unrelated widgets, or a `useEffect` firing with the wrong dependencies — bugs that are hard to trace back to the loop.

This is the loop half of the rules of hooks; [`avoid_conditional_hooks`](/docs/rules/hook-rules/avoid-conditional-hooks/) covers the branching half.

**See also:** [flutter_hooks rules](https://pub.dev/packages/flutter_hooks#rules)

## Don't

```dart
class MyWidget extends HookWidget {
  const MyWidget(this.items);
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    // The hook count changes with items.length
    for (final item in items) {
      final controller = useTextEditingController(text: item);
    }
    return const SizedBox();
  }
}
```

## Do

```dart
class MyWidget extends HookWidget {
  const MyWidget(this.items);
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    // One hook call, regardless of how many items there are
    final controllers = useMemoized(
      () => items.map((i) => TextEditingController(text: i)).toList(),
      [items],
    );
    return const SizedBox();
  }
}
```

If each item genuinely needs its own hook state, give each one its own hook widget and let the framework keep the contexts separate.

## Known limitations

Only loops are detected. A hook placed after an early `return` is skipped on some builds and shifts positions the same way, but proving that requires flow analysis and is out of scope here.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_misused_hooks: false
```
