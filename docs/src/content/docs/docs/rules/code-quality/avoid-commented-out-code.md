---
title: avoid_commented_out_code
description: "Detect and flag commented-out code."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_commented_out_code
---

<span class="rule-badge rule-badge--version">v0.3.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Code Quality</span>

Flags comments that look like commented-out Dart code rather than descriptive text. This includes commented-out function definitions, variable declarations, import statements, and other recognizable code patterns. The quick fix removes the flagged comment block.

## Why use this rule

Commented-out code is technical debt that clutters the codebase and confuses readers about what is intentional. Version control already preserves old code, making commented-out blocks unnecessary. Removing them keeps the codebase clean and reduces cognitive load during code review.

**See also:** [Effective Dart: Documentation](https://dart.dev/effective-dart/documentation)

## Don't

```dart
class BadExamples {
  // void apply(String value) {
  //   print(value);
  // }

  // final x = 42;

  // import 'dart:async';

  void another() {}
}
```

## Do

```dart
class GoodExamples {
  // This method handles the main processing logic
  // and delegates to the appropriate handler

  // Temporarily disabled, enable in 1.0
  void another() {}
}
```

## Known limitations

Detection is a heuristic over each block of comments: a block is reported when at least half its non-empty lines look like Dart rather than prose. Blocks are formed from comments on directly consecutive lines — a blank line ends one, and so does any code between them. A comment trailing code (`foo(); // note`) is its own block, since it annotates the line beside it.

That means a single commented-out line surrounded by explanatory prose may not reach the ratio, and prose that reads like code (`// returns null;`) can be reported. Suppress those with `// ignore: many_lints/avoid_commented_out_code`.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_commented_out_code: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

### Options

Configure in `many_lints.yaml` at your package root:

```yaml
rules:
  avoid_commented_out_code:
    min_lines: 2
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `min_lines` | int | `1` | Minimum number of consecutive commented-out lines before a block is reported |

Alternatively, use a top-level `many_lints:` section in `analysis_options.yaml`.
Note this section does **not** inherit through `include:`; when both sources
exist, `many_lints.yaml` wins and the section is ignored entirely.
