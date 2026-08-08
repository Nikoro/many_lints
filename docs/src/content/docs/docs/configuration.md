---
title: Configuration
description: How to install and configure many_lints in your Flutter & Dart project.
---

## Installation

Add `many_lints` to the **top-level** `plugins` section in your `analysis_options.yaml` file (NOT under `analyzer:`):

```yaml
plugins:
  many_lints: ^0.8.0
```

The analysis server will automatically download and resolve the plugin from [pub.dev](https://pub.dev/packages/many_lints). There is no need to add it to your `pubspec.yaml`.

> **Requires Dart 3.11+ (Flutter 3.41+)**

## Extended syntax

You can use the extended syntax to pin a version:

```yaml
plugins:
  many_lints:
    version: ^0.8.0
```

## Local development

For local development or when using many_lints from a cloned repository, use the `path` option:

```sh
git clone https://github.com/Nikoro/many_lints.git /path/to/many_lints
```

```yaml
plugins:
  many_lints:
    path: /path/to/many_lints
```

Git dependencies are also supported and use the same syntax as package
dependencies:

```yaml
plugins:
  many_lints:
    git: https://github.com/Nikoro/many_lints.git
```

## Configuring diagnostics

All 133 rules are registered as warnings and enabled by default. You can enable or disable individual rules under the `diagnostics` key:

```yaml
plugins:
  many_lints:
    version: ^0.8.0
    diagnostics:
      prefer_center_over_align: true
      use_bloc_suffix: false
```

## Excluding paths per rule

`diagnostics:` turns a rule on or off everywhere. To keep a rule on but silence it for
certain paths, write a `rules:` block — in **either** of these two places, whichever
you prefer.

### Option A — in `analysis_options.yaml`

Under a top-level `many_lints:` key. Note it is top-level: a sibling of `plugins:`,
not nested inside it.

```yaml
# analysis_options.yaml
plugins:
  many_lints: ^0.8.0

many_lints:
  rules:
    avoid_only_rethrow:
      exclude:
        - test/**
        - "**/*.g.dart"
```

### Option B — in a separate `many_lints.yaml`

Placed next to your `pubspec.yaml`.

```yaml
# many_lints.yaml
rules:
  avoid_only_rethrow:
    exclude:
      - test/**
      - "**/*.g.dart"
```

### Which to pick

Both are fully equivalent — the `rules:` block is identical, it just sits one level
deeper in Option A. Use Option A to keep everything in one file, or Option B to keep
lint configuration separate.

### What `exclude` accepts

Every rule supports `exclude`. Each `exclude` sits under one rule and affects only that
rule — excluding a path from `avoid_only_rethrow` says nothing about the other rules.
To skip a path for several rules, give each of them its own `exclude`.

Patterns are globs matched against the path relative to the package root, using the same
glob semantics as the analyzer's own `analyzer: exclude:`. A plain path is a valid
pattern too, and the list can hold as many entries as you need:

```yaml
rules:
  avoid_only_rethrow:
    exclude:
      - lib/legacy/parser.dart      # one specific file
      - lib/generated/**            # a whole directory tree
      - "**/*.g.dart"               # every generated file
  prefer_type_over_var:
    exclude:
      - test/**                     # a different rule, its own list
```

:::caution[If you create both]
`many_lints.yaml` wins outright and the `analysis_options.yaml` section is ignored —
the two are **not** merged.
:::

:::note[Two limitations worth knowing]
The `rules:` block cannot live *inside* `plugins: many_lints:`. The analyzer accepts
only enable/disable and severity there, and reports any other key as an unsupported
option — which is why the configuration sits either one level up or in its own file.

The top-level `many_lints:` section is also **not** inherited through `include:`,
because the analyzer never parses it. If you share a base `analysis_options.yaml`
across packages, use Option B in each package instead.
:::

Some rules also accept options that change what they report; those are listed in the
**Configuration** section of the individual rule's page.

## Suppressing diagnostics

To suppress a specific lint, use comments:

```dart
// ignore: many_lints/prefer_center_over_align
const Align(...);

// ignore_for_file: many_lints/use_bloc_suffix
```

:::caution[The `many_lints/` prefix is required]
Unlike SDK lints, a plugin diagnostic is only silenced when the rule name is prefixed with the plugin name. A bare `// ignore: prefer_center_over_align` has **no effect** — the analyzer matches the plugin name alongside the rule name, and a comment without a prefix carries none, so it never matches.

The prefix is the package name used as the key under `plugins:` in
`analysis_options.yaml`.

```dart
// ignore: prefer_center_over_align             // ❌ does nothing
// ignore: many_lints/prefer_center_over_align  // ✅ works
```

Suppressing by diagnostic type also works, and needs the `type=` form — plain `// ignore: lint` has no effect. Note this silences *every* lint on that line, including SDK ones:

```dart
// ignore: type=lint
```
:::

## Restarting the analysis server

:::caution
After any change to the `plugins` section, you must restart the Dart Analysis Server for changes to take effect.
:::

**VS Code**: Open the command palette (`Cmd+Shift+P` / `Ctrl+Shift+P`) and run `Dart: Restart Analysis Server`.

**Android Studio / IntelliJ**: Go to `File → Invalidate Caches / Restart`, or use the Dart Analysis panel to restart.
