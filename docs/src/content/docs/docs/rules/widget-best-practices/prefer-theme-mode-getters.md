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

Warns when a `ThemeMode` value is compared with `==` or `!=` against a `ThemeMode` constant. Flutter 3.44 added dedicated getters — `isDark`, `isLight`, and `isSystem` — that express the same check more directly.

## Why use this rule

`mode.isDark` reads as intent rather than mechanics and matches the direction of the Flutter API. The getters also make call sites shorter and remove the duplicated `ThemeMode.` noise from conditions.

The rule only reports when the resolved `ThemeMode` enum actually declares the getter, so it stays silent on projects using Flutter older than 3.44 and the quick fix can never produce non-compiling code.

**See also:** [Flutter 3.44.0 release notes](https://docs.flutter.dev/release/release-notes/release-notes-3.44.0)

## Don't

```dart
// LINT: compares against the enum constant
if (themeMode == ThemeMode.dark) {
  applyDarkStyle();
}

// LINT: negated comparison
final showSun = themeMode != ThemeMode.dark;
```

## Do

```dart
if (themeMode.isDark) {
  applyDarkStyle();
}

final showSun = !themeMode.isDark;
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_theme_mode_getters: false
```
