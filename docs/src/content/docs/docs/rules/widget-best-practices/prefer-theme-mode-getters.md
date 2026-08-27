---
title: prefer_theme_mode_getters
description: "Prefer ThemeMode.isDark/isLight/isSystem getters (Flutter 3.44+) over == comparisons."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_theme_mode_getters
---

<span class="rule-badge rule-badge--version">v0.7.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

Flags a `ThemeMode` compared with `==` or `!=` against `ThemeMode.dark`, `ThemeMode.light` or `ThemeMode.system`. Flutter 3.44 added `isDark`, `isLight` and `isSystem`, which say the same thing without the repeated `ThemeMode.` noise. The quick fix rewrites the comparison.

This rule is in the **`opinionated`** preset, so it is on with `preset: opinionated` and `preset: pedantic`. No configuration.

**See also:** [Flutter 3.44.0 release notes](https://docs.flutter.dev/release/release-notes/release-notes-3.44.0)

## Don't

```dart
final themeMode = ThemeMode.dark;

// LINT: compares against the enum constant
if (themeMode == ThemeMode.dark) {
  applyDarkStyle();
}

// LINT: negated comparison
final showSun = themeMode != ThemeMode.dark;
```

## Do

```dart
final themeMode = ThemeMode.dark;

if (themeMode.isDark) {
  applyDarkStyle();
}

final showSun = !themeMode.isDark;
```

### The constant can be on either side

```dart
// Don't
final isLight = ThemeMode.light == settings.themeMode;

// Do
final isLight = settings.themeMode.isLight;
```

### In a widget

The most common site is a build method branching on the app's mode:

```dart
// Don't
@override
Widget build(BuildContext context) {
  return Icon(
    settings.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
  );
}

// Do
@override
Widget build(BuildContext context) {
  return Icon(
    settings.themeMode.isDark ? Icons.dark_mode : Icons.light_mode,
  );
}
```

## Known limitations

**Nothing is reported before Flutter 3.44.** The rule checks that the resolved `ThemeMode` enum actually declares the getter, so an older Flutter sees no diagnostics and the quick fix can never produce non-compiling code.

A `switch` on `ThemeMode` is not reported — the getters do not replace exhaustive matching, and a switch is usually the better shape when all three cases matter.

## Turning this rule off

```yaml
# many_lints.yaml
rules:
  prefer_theme_mode_getters: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`always_pass_global_key`](/many_lints/docs/rules/widget-best-practices/always-pass-global-key/) — Don't create a GlobalKey inside build.
- [`avoid_conditional_hooks`](/many_lints/docs/rules/widget-best-practices/avoid-conditional-hooks/) — Never call hooks inside conditionals, loops, or ternaries.
- [`avoid_deep_widget_nesting`](/many_lints/docs/rules/widget-best-practices/avoid-deep-widget-nesting/) — Keep a widget tree within a nesting budget.
- [`avoid_flexible_outside_flex`](/many_lints/docs/rules/widget-best-practices/avoid-flexible-outside-flex/) — Only use Flexible and Expanded as direct children of Row, Column, or Flex.
