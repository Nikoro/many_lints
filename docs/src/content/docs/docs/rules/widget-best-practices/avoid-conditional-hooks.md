---
title: avoid_conditional_hooks
description: "Never call hooks inside conditionals, loops, or ternaries"
sidebar:
  label: avoid_conditional_hooks
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

Flags a hook call (`useState`, `useMemoized`, `useEffect`, …) reached only conditionally: inside an `if`, a ternary, a `switch`, an `if` element in a collection, or the right-hand side of `&&` / `||`.

The hooks framework tracks state by call *order*, not by name. Skip a hook on one build and every hook after it shifts position and reads the wrong slot — values swap between hooks, or the build throws. This is the same "Rules of Hooks" constraint as React.

This rule is in the **`core`** preset, so it is on with `preset: core` and every preset above it. No configuration.

**See also:** [flutter_hooks](https://pub.dev/packages/flutter_hooks) | [React Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks)

## Don't

```dart
class ProfileView extends HookWidget {
  const ProfileView({required this.userId, super.key});

  final String? userId;

  @override
  Widget build(BuildContext context) {
    // Skipped whenever userId is null — every later hook shifts a slot
    if (userId != null) {
      final profile = useMemoized(() => loadProfile(userId!), [userId]);
      return Text(profile);
    }

    final theme = useState(ThemeMode.system);
    return Text('${theme.value}');
  }
}
```

## Do

Call the hook unconditionally and put the branch *inside* it. The call order is then the same on every build:

```dart
class ProfileView extends HookWidget {
  const ProfileView({required this.userId, super.key});

  final String? userId;

  @override
  Widget build(BuildContext context) {
    final profile = useMemoized(
      () => userId == null ? '' : loadProfile(userId!),
      [userId],
    );
    final theme = useState(ThemeMode.system);

    if (userId == null) return Text('${theme.value}');
    return Text(profile);
  }
}
```

### Ternaries and `&&` count too

Both branches of a ternary and the right operand of a short-circuit operator are conditionally executed, so hooks there are reported:

```dart
// Don't
final label = isCompact ? useState('S').value : useState('L').value;
final ready = isLoggedIn && useIsMounted()();

// Do — one unconditional call, branch on its value
final size = useState(isCompact ? 'S' : 'L');
final mounted = useIsMounted();
final isReady = isLoggedIn && mounted();
```

## Known limitations

**Loops are not this rule's job.** A hook in a `for` or `while` body is reported by [`avoid_misused_hooks`](/many_lints/docs/rules/hook-rules/avoid-misused-hooks/) instead — this rule only tracks branches.

The condition of an `if` or a ternary is *not* conditional — a hook there runs on every build, so it is left alone.

Hooks inside a nested closure are not reported by this rule; the closure is its own invocation context, and calling a hook from one is [`avoid_hooks_outside_build`](/many_lints/docs/rules/hook-rules/avoid-hooks-outside-build/)'s job. A `HookBuilder` starts a fresh hook context, so its `builder` body is checked on its own rather than as part of the enclosing build.

## Turning this rule off

```yaml
# many_lints.yaml
rules:
  avoid_conditional_hooks: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_unnecessary_hook_widgets`](/many_lints/docs/rules/widget-best-practices/avoid-unnecessary-hook-widgets/) — Don't extend HookWidget if you never call any hooks.
- [`avoid_hooks_outside_build`](/many_lints/docs/rules/hook-rules/avoid-hooks-outside-build/) — Only call hooks from a hook context.
- [`avoid_misused_hooks`](/many_lints/docs/rules/hook-rules/avoid-misused-hooks/) — Don't call hooks inside loops.
- [`always_pass_global_key`](/many_lints/docs/rules/widget-best-practices/always-pass-global-key/) — Don't create a GlobalKey inside build.
