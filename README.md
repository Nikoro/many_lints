<p align="center">
  <a href="https://pub.dev/packages/many_lints"><img src="https://raw.githubusercontent.com/nikoro/many_lints/main/logo/logo.webp" width="800"/></a>
</p>
<p align="center">
  <a href="https://pub.dev/packages/many_lints">
    <img alt="Pub Package" src="https://tinyurl.com/23wn29m7">
  </a>
  <a href="https://github.com/Nikoro/many_lints/actions">
    <img alt="Build Status" src="https://img.shields.io/github/actions/workflow/status/Nikoro/many_lints/ci.yaml?label=build">
  </a>
  <a href="https://github.com/Nikoro/many_lints/actions">
    <img src="https://img.shields.io/badge/coverage-95%25-brightgreen" alt="coverage 95%">
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img alt="MIT License" src="https://tinyurl.com/3uf9tzpy">
  </a>
  <a href="https://pub.dev/packages/analyzer">
    <img src="https://img.shields.io/badge/analyzer-14.1.0-blue" alt="analyzer version 14.1.0">
  </a>
  <a href="https://nikoro.github.io/many_lints">
    <img src="https://img.shields.io/badge/docs-many__lints-154A95" alt="Documentation">
  </a>
</p>

A useful collection of custom lints for Flutter & Dart projects. Uses the new `analysis_server_plugin` system for direct integration with `dart analyze` and IDEs.

**[Browse all rules on the documentation site](https://nikoro.github.io/many_lints)**

## Getting started

> **Requires Dart 3.11+ (Flutter 3.41+)**

Add `many_lints` to the **top-level** `plugins` section in your `analysis_options.yaml` file (NOT under `analyzer:`):

```yaml
plugins:
  many_lints: ^1.1.0
```

The analysis server will automatically download and resolve the plugin from [pub.dev](https://pub.dev/packages/many_lints). There is no need to add it to your `pubspec.yaml`.

Rules are opt-in. The quickest setup is a preset:

```yaml
# analysis_options.yaml (recommended)
many_lints:
  preset: recommended
```

But a preset is optional. You can instead enable only selected rules, or start from a
preset and override individual rules:

```yaml
# analysis_options.yaml
many_lints:
  rules:
    avoid_equal_expressions: true
    avoid_only_rethrow: true
```

Alternatively, put the same `preset:` and `rules:` keys in a standalone
`many_lints.yaml` next to `pubspec.yaml`.

```yaml
# many_lints.yaml — alternative standalone file
rules:
  avoid_equal_expressions: true
  avoid_only_rethrow: true
```

> **Seeing no warnings?** No rule is enabled yet. Choose a preset or enable rules by name.

> **Important**: After any change to the `plugins` section, you must restart the Dart Analysis Server.

### Presets

Presets are cumulative: moving right only adds rules.

| Preset | Rules | Choose it when... |
|--------|------:|-------------------|
| `none` | 0 | You want to enable every rule manually. This is the default. |
| `core` | 35 | You want only near-certain bugs and runtime failures. |
| `recommended` | 97 | You want safe production defaults. Best starting point for most projects. |
| `opinionated` | 184 | You also want a consistent Many Lints house style. |
| `pedantic` | 241 | You want strict naming, ordering, structure and complexity limits. |

There is no "all" preset: some rules intentionally conflict, and config-only rules such
as `avoid_banned_imports` cannot have useful defaults. See the
[preset comparison](https://nikoro.github.io/many_lints/docs/presets/) for the exact rules
in every tier.

Presets select only Many Lints rules. Enable official
[Dart SDK lints](https://dart.dev/tools/linter-rules) separately through the standard
`linter: rules:` configuration.

### Rules in one example

The recommended location is the top-level `many_lints:` section in
`analysis_options.yaml`, alongside `plugins:`:

```yaml
# analysis_options.yaml
plugins:
  many_lints: ^1.1.0

many_lints:
  preset: recommended
  rules:
    prefer_type_over_var: true       # add a rule outside the preset
    avoid_only_rethrow: false        # remove a rule from the preset

    avoid_long_functions:
      include: lib/domain/**         # run only in matching paths
      exclude: "**/*.g.dart"         # exclude wins if both match
      message: Extract a focused helper.
      max_lines: 80                  # rule-specific option
```

Or keep only the Many Lints configuration in a separate file:

```yaml
# many_lints.yaml — next to pubspec.yaml
preset: recommended
rules:
  prefer_type_over_var: true
  avoid_only_rethrow: false
  avoid_long_functions:
    include: lib/domain/**
    exclude: "**/*.g.dart"
    message: Extract a focused helper.
    max_lines: 80
```

If both locations exist, `many_lints.yaml` wins; they are not merged.

| Key | Meaning |
|-----|---------|
| `enabled` / `true` / `false` | Enables or disables one rule; overrides a preset when present. |
| `include` | Runs the rule only for matching package-relative globs. String or list. |
| `exclude` | Skips matching paths. String or list; takes precedence over `include`. |
| `message` | Appends a project-specific note without changing the diagnostic code or fix. |
| Rule options | Change what a configurable rule reports; defaults preserve normal behaviour. |

Every rule supports `include`, `exclude` and `message`. Adding one of these keys or a
rule-specific option also opts the rule in unless `enabled: false` is set. Options and
defaults are listed on each
[rule page](https://nikoro.github.io/many_lints/docs/rules/); the complete syntax is in the
[configuration guide](https://nikoro.github.io/many_lints/docs/configuration/).

### Severity

Enablement belongs to `preset:` / `rules:`. Severity belongs to the plugin's analyzer
configuration:

```yaml
plugins:
  many_lints:
    version: ^1.1.0
    diagnostics:
      avoid_equal_expressions: error   # error | warning | info
```

`diagnostics:` cannot enable a rule that is not enabled through `preset:` or `rules:`.
The `rules:` block cannot be
nested inside `plugins: many_lints`, and top-level `many_lints:` configuration is not
inherited through the analyzer's YAML `include:`. See
[configuration locations and limitations](https://nikoro.github.io/many_lints/docs/configuration/#which-to-pick)
for shared-config setups.

## Available Lints

259 lints with 104 quick fixes. All are off by default — enable selected rules by name,
use a [preset](#presets), or combine a preset with per-rule overrides. Each rule links to
its full documentation with examples and fix details.

| Category | Rules | Description |
|----------|------:|-------------|
| [Class Naming](https://nikoro.github.io/many_lints/docs/rules/#class-naming) | 12 | Class and type naming conventions |
| [Architecture](https://nikoro.github.io/many_lints/docs/rules/#architecture) | 6 | Configurable bans on imports, types, names and members |
| [Bloc / Riverpod](https://nikoro.github.io/many_lints/docs/rules/#bloc-riverpod) | 12 | BLoC and Riverpod state management patterns |
| [Riverpod State](https://nikoro.github.io/many_lints/docs/rules/#riverpod-state) | 9 | Riverpod-specific state rules |
| [Async Safety](https://nikoro.github.io/many_lints/docs/rules/#async-safety) | 12 | Async/await and state mutation safety |
| [fpdart](https://nikoro.github.io/many_lints/docs/rules/#fpdart) | 22 | Functional error handling with Either, Option and TaskEither |
| [Widget Best Practices](https://nikoro.github.io/many_lints/docs/rules/#widget-best-practices) | 25 | General widget best practices |
| [Widget Replacement](https://nikoro.github.io/many_lints/docs/rules/#widget-replacement) | 13 | Simpler widget alternatives |
| [State Management](https://nikoro.github.io/many_lints/docs/rules/#state-management) | 9 | StatefulWidget and state patterns |
| [Control Flow](https://nikoro.github.io/many_lints/docs/rules/#control-flow) | 29 | Control flow statements and patterns |
| [Collection & Type](https://nikoro.github.io/many_lints/docs/rules/#collection-type) | 20 | Collection and type-related checks |
| [Pattern Matching](https://nikoro.github.io/many_lints/docs/rules/#pattern-matching) | 6 | Dart pattern matching best practices |
| [Type Annotations](https://nikoro.github.io/many_lints/docs/rules/#type-annotations) | 8 | Type annotation conventions |
| [Code Organization](https://nikoro.github.io/many_lints/docs/rules/#code-organization) | 17 | Code structure and organization |
| [Shorthand Patterns](https://nikoro.github.io/many_lints/docs/rules/#shorthand-patterns) | 5 | Dot shorthand syntax patterns |
| [Hook Rules](https://nikoro.github.io/many_lints/docs/rules/#hook-rules) | 4 | Flutter Hooks conventions |
| [Testing Rules](https://nikoro.github.io/many_lints/docs/rules/#testing-rules) | 8 | Testing best practices and matchers |
| [Resource Management](https://nikoro.github.io/many_lints/docs/rules/#resource-management) | 5 | Resource cleanup and disposal |
| [Code Quality](https://nikoro.github.io/many_lints/docs/rules/#code-quality) | 34 | General code quality improvements |
| [Formatting](https://nikoro.github.io/many_lints/docs/rules/#formatting) | 3 | Literal formatting conventions |

## Available Assists

Assists are refactorings you invoke deliberately from the lightbulb menu (<kbd>Ctrl</kbd>/<kbd>Cmd</kbd> + <kbd>.</kbd> in VS Code). Unlike quick fixes they are not attached to a diagnostic, so they are always available — including where no rule is enabled at all.

| Assist | Where the cursor goes | What it does |
|--------|-----------------------|--------------|
| **Convert to collection-for** | a `.map()` call | `.map().toList()` / `.map().toSet()` → collection-for syntax |
| **Convert to `Do` notation** | any `flatMap` in a nest | Flattens nested `flatMap` callbacks into an fpdart `Do` block, offering every generated name as a linked rename |
| **Convert to `flatMap` chain** | anywhere in a `Do` block | The inverse: unfolds a straight-line `Do` block back into nested `flatMap` callbacks |
| **Convert to `TaskEither` / `TaskOption`** | a function returning `Future<Either>`, `Either`, `Future<Option>` or `Option` | Converts the signature and moves the body into the lazy fpdart type, so the pipeline can host an `await` |
| **Expand `tryCatch` into `try`/`catch`** | a `tryCatch` constructor | `Either.tryCatch` / `TaskEither.tryCatch` / `Option.tryCatch` → an explicit `try`/`catch` |
| **Convert null check to pattern** | an `if (x != null)` guard | `if (x != null)` → `if (x case final y?)`, so a checked *field* is promoted and the `!` inside the branch disappears. Semantics-preserving |
| **Convert null check to destructuring pattern** | an `if (x != null)` guard whose branch asserts `x!.field!` | `if (x case Type(:final field?))`, folding both null checks into one pattern. **Narrows the condition** — offered only where the branch already asserts the field |

See the [assists documentation](https://nikoro.github.io/many_lints/docs/assists/) for examples and the cases each one declines.

## Suppressing Diagnostics

To suppress a specific lint, use comments:

```dart
// ignore: many_lints/prefer_center_over_align
const example = Align(alignment: Alignment.center);

// ignore_for_file: many_lints/use_class_suffix
```

The `many_lints/` prefix is **required**. Unlike SDK lints, a plugin diagnostic is only silenced when the rule name is prefixed with the plugin name, so a bare `// ignore: prefer_center_over_align` has no effect. The prefix is the key used under `plugins:` in `analysis_options.yaml`.

Suppressing by type is also possible via `// ignore: type=lint` (the `type=` form is required, and it silences every lint on that line, SDK ones included).

## Example

See the [`example/`](example/) directory for a Flutter project that demonstrates every lint rule in action. Each file corresponds to a single rule and contains code that triggers the lint.
