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
  many_lints: ^1.0.0
```

The analysis server will automatically download and resolve the plugin from [pub.dev](https://pub.dev/packages/many_lints). There is no need to add it to your `pubspec.yaml`.

Then pick a preset. **Every rule is off until you do**, so installing the plugin never floods an existing codebase:

```yaml
# many_lints.yaml — next to your pubspec.yaml
preset: recommended
```

> **Seeing no warnings?** That is expected without a preset, not a broken install.

> **Important**: After any change to the `plugins` section, you must restart the Dart Analysis Server.

For local development setup, see [CONTRIBUTING.md](CONTRIBUTING.md).

### Presets

| Preset | Rules | Contents |
|--------|-------|----------|
| `none` | 0 | Nothing. The default, and the explicit way to opt out. |
| `core` | 37 | Near-certain bugs only — dead conditions, impossible casts, leaked resources. |
| `recommended` | 100 | `core` plus idiomatic, uncontroversial Dart and Flutter practice. |
| `opinionated` | 165 | `recommended` plus this package's own style preferences. |

Each preset builds on the one above it, the same way `package:lints/recommended.yaml` includes `core.yaml`. `core` and `recommended` deliberately exclude anything that imposes an architecture, a naming scheme, or a contested style choice.

There is deliberately no preset that enables every rule: some rules contradict one another (`prefer_container` vs `prefer_padding_over_container`, `use_gap` vs `prefer_spacing`), so enabling both halves would produce two diagnostics on one line whose fixes undo each other. `opinionated` takes one side of each pair; the other stays available by name. Rules that do nothing until configured, such as the `banned_*` family, are also left out.

Adjust a preset in either direction without restating it:

```yaml
# many_lints.yaml
preset: recommended
rules:
  prefer_type_over_var: true     # add a rule the preset omits
  avoid_only_rethrow: false      # drop one it includes
```

Configuring a rule by name — an `exclude:`, an option, a `message:` — also opts it in.

### Configuring severity

`preset:` decides *whether* a rule runs. To change how loudly it reports, use the analyzer's `diagnostics` key:

```yaml
plugins:
  many_lints:
    version: ^1.0.0
    diagnostics:
      avoid_equal_expressions: error   # error | warning | info
```

### Excluding paths per rule

A preset turns a rule on everywhere. To keep a rule on but skip certain paths, write a `rules:` block — in **either** of these two places, whichever you prefer:

**Option A — in your existing `analysis_options.yaml`**, under a top-level `many_lints:` key (note: top-level, a sibling of `plugins:`, not nested inside it):

```yaml
# analysis_options.yaml
plugins:
  many_lints: ^1.0.0

many_lints:
  rules:
    avoid_only_rethrow:
      exclude:
        - test/**
        - "**/*.g.dart"
```

**Option B — in a separate `many_lints.yaml`** next to your `pubspec.yaml`:

```yaml
# many_lints.yaml
rules:
  avoid_only_rethrow:
    exclude:
      - test/**
      - "**/*.g.dart"
```

Both are fully equivalent — the `rules:` block is identical, it just sits one level deeper in Option A. Use Option A to keep everything in one file, or Option B to keep lint config separate.

If you create both, `many_lints.yaml` wins outright and the `analysis_options.yaml` section is ignored — they are **not** merged.

Every rule supports `exclude`. Each `exclude` sits under one rule and affects only that rule — to skip a path for several rules, give each of them its own `exclude`.

Patterns are globs matched against the path relative to the package root, using the same semantics as the analyzer's own `analyzer: exclude:`. A plain path is a valid pattern too, and the list can hold as many entries as you need:

```yaml
rules:
  avoid_only_rethrow:
    exclude:
      - lib/legacy/parser.dart      # one specific file
      - lib/generated/**            # a whole directory tree
      - "**/*.g.dart"               # every generated file
```

> The `rules:` block cannot live *inside* `plugins: many_lints:` — the analyzer only accepts enable/disable and severity there, and reports any other key as an unsupported option.

See [Configuration](https://nikoro.github.io/many_lints/docs/configuration/#excluding-paths-per-rule) for details.

## Available Lints

183 lints with 97 quick fixes. All are off by default — enable them with a [preset](#presets). Each rule links to its full documentation with examples and fix details.

| Category | Rules | Description |
|----------|------:|-------------|
| [Class Naming](https://nikoro.github.io/many_lints/docs/rules/class-naming/) | 2 | Class and type naming conventions |
| [Architecture](https://nikoro.github.io/many_lints/docs/rules/architecture/) | 6 | Configurable bans on imports, types, names and members |
| [Bloc / Riverpod](https://nikoro.github.io/many_lints/docs/rules/bloc-riverpod/) | 12 | BLoC and Riverpod state management patterns |
| [Riverpod State](https://nikoro.github.io/many_lints/docs/rules/riverpod-state/) | 9 | Riverpod-specific state rules |
| [Async Safety](https://nikoro.github.io/many_lints/docs/rules/async-safety/) | 8 | Async/await and state mutation safety |
| [fpdart](https://nikoro.github.io/many_lints/docs/rules/fpdart/) | 22 | Functional error handling with Either, Option and TaskEither |
| [Widget Best Practices](https://nikoro.github.io/many_lints/docs/rules/widget-best-practices/) | 21 | General widget best practices |
| [Widget Replacement](https://nikoro.github.io/many_lints/docs/rules/widget-replacement/) | 13 | Simpler widget alternatives |
| [State Management](https://nikoro.github.io/many_lints/docs/rules/state-management/) | 9 | StatefulWidget and state patterns |
| [Control Flow](https://nikoro.github.io/many_lints/docs/rules/control-flow/) | 18 | Control flow statements and patterns |
| [Collection & Type](https://nikoro.github.io/many_lints/docs/rules/collection-type/) | 20 | Collection and type-related checks |
| [Pattern Matching](https://nikoro.github.io/many_lints/docs/rules/pattern-matching/) | 6 | Dart pattern matching best practices |
| [Type Annotations](https://nikoro.github.io/many_lints/docs/rules/type-annotations/) | 5 | Type annotation conventions |
| [Code Organization](https://nikoro.github.io/many_lints/docs/rules/code-organization/) | 4 | Code structure and organization |
| [Shorthand Patterns](https://nikoro.github.io/many_lints/docs/rules/shorthand-patterns/) | 5 | Dot shorthand syntax patterns |
| [Hook Rules](https://nikoro.github.io/many_lints/docs/rules/hook-rules/) | 4 | Flutter Hooks conventions |
| [Testing Rules](https://nikoro.github.io/many_lints/docs/rules/testing-rules/) | 3 | Testing best practices and matchers |
| [Resource Management](https://nikoro.github.io/many_lints/docs/rules/resource-management/) | 4 | Resource cleanup and disposal |
| [Code Quality](https://nikoro.github.io/many_lints/docs/rules/code-quality/) | 12 | General code quality improvements |

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
const Align(...);

// ignore_for_file: many_lints/use_class_suffix
```

The `many_lints/` prefix is **required**. Unlike SDK lints, a plugin diagnostic is only silenced when the rule name is prefixed with the plugin name, so a bare `// ignore: prefer_center_over_align` has no effect. The prefix is the key used under `plugins:` in `analysis_options.yaml`.

Suppressing by type is also possible via `// ignore: type=lint` (the `type=` form is required, and it silences every lint on that line, SDK ones included).

## Example

See the [`example/`](example/) directory for a Flutter project that demonstrates every lint rule in action. Each file corresponds to a single rule and contains code that triggers the lint.
