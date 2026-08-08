---
title: avoid_banned_exports
description: "Ban re-exports of specific libraries, optionally scoped by directory"
sidebar:
  label: avoid_banned_exports
---

<span class="rule-badge rule-badge--version">Unreleased</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Architecture</span>

Flags `export` directives for libraries you ban, optionally only inside the directories you name. Barrel-file hygiene: it keeps internal libraries out of a package's public API.

**This rule reports nothing until you configure it.**

## Why use this rule

A barrel file decides what a package promises. An `export` added there for convenience — to save one import in a test, say — silently makes everything in that library public, and removing it later is a breaking change for every consumer.

This is kept separate from [`avoid_banned_imports`](/many_lints/docs/rules/architecture/avoid-banned-imports/) on purpose: depending on a library internally and re-exporting it to consumers are different decisions. A package is often perfectly free to use something it must not expose.

**See also:** [Effective Dart: libraries](https://dart.dev/effective-dart/usage#libraries), [Dart package layout conventions](https://dart.dev/tools/pub/package-layout#public-libraries)

## Don't

```dart
// in lib/my_package.dart
//
// With an entry banning 'src/internal/.*' in lib/*.dart:
export 'src/internal/cache.dart';  // LINT: makes the cache public API
```

## Do

```dart
// in lib/my_package.dart
//
// Export only what consumers are meant to depend on.
export 'src/api/client.dart';
export 'src/api/models.dart';
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_banned_exports: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

### Options

Configure in `many_lints.yaml` at your package root:

```yaml
rules:
  avoid_banned_exports:
    banned:
      - deny_pattern: ['src/internal/.*']
        in: ['lib/*.dart']
        message: 'Internal libraries must not be part of the public API.'
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `banned` | list of maps | `[]` | The entries to enforce. With none, the rule reports nothing |

Each entry accepts:

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `deny` | string or list | one of `deny` / `deny_pattern` | Export URIs banned by **exact** match |
| `deny_pattern` | string or list | one of `deny` / `deny_pattern` | Regular expressions, anchored to the whole URI |
| `in` | list of globs | no | Paths, relative to the package root, where the entry applies. Omit to apply everywhere |
| `message` | string | no | A project-specific explanation appended to the diagnostic |

The URI is matched as written in the `export` directive, so a relative export is matched as the relative path you typed.

Scoping with `in: ['lib/*.dart']` is the useful default here: a single `*` matches only top-level barrel files, leaving everything under `lib/src/**` free to export internally.

Alternatively, use a top-level `many_lints:` section in `analysis_options.yaml`.
Note this section does **not** inherit through `include:`; when both sources
exist, `many_lints.yaml` wins and the section is ignored entirely.

## Related rules

- [`avoid_banned_imports`](/many_lints/docs/rules/architecture/avoid-banned-imports/) — bans depending on a library, rather than exposing it
