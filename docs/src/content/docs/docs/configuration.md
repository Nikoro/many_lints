---
title: Configuration
description: How to install and configure many_lints in your Flutter & Dart project.
---

## Installation

Add `many_lints` to the **top-level** `plugins` section in your `analysis_options.yaml` file (NOT under `analyzer:`):

```yaml
plugins:
  many_lints: ^0.4.0
```

The analysis server will automatically download and resolve the plugin from [pub.dev](https://pub.dev/packages/many_lints). There is no need to add it to your `pubspec.yaml`.

> **Requires Dart 3.10+ (Flutter 3.38+)**

## Extended syntax

You can use the extended syntax to pin a version:

```yaml
plugins:
  many_lints:
    version: ^0.4.0
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

:::note
Git dependencies are not directly supported by the plugin system. Clone the repository locally and use the `path` option instead.
:::

## Configuring diagnostics

All 100 rules are registered as warnings and enabled by default. You can enable or disable individual rules under the `diagnostics` key:

```yaml
plugins:
  many_lints:
    version: ^0.4.0
    diagnostics:
      prefer_center_over_align: true
      use_bloc_suffix: false
```

## Suppressing diagnostics

To suppress a specific lint, use comments:

```dart
// ignore: many_lints/prefer_center_over_align
const Align(...);

// ignore_for_file: many_lints/use_bloc_suffix
```

## Restarting the analysis server

:::caution
After any change to the `plugins` section, you must restart the Dart Analysis Server for changes to take effect.
:::

**VS Code**: Open the command palette (`Cmd+Shift+P` / `Ctrl+Shift+P`) and run `Dart: Restart Analysis Server`.

**Android Studio / IntelliJ**: Go to `File → Invalidate Caches / Restart`, or use the Dart Analysis panel to restart.
