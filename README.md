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
    <img src="https://img.shields.io/badge/coverage-98%25-brightgreen" alt="coverage 98%">
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
  many_lints: ^0.8.0
```

That's it — the analysis server will automatically download and resolve the plugin from [pub.dev](https://pub.dev/packages/many_lints). There is no need to add it to your `pubspec.yaml`.

> **Important**: After any change to the `plugins` section, you must restart the Dart Analysis Server.

For local development setup, see [CONTRIBUTING.md](CONTRIBUTING.md).

### Configuring diagnostics

All rules are registered as warnings and enabled by default. You can enable or disable individual rules under the `diagnostics` key:

```yaml
plugins:
  many_lints:
    version: ^0.8.0
    diagnostics:
      prefer_center_over_align: true
      use_bloc_suffix: false
```

## Available Lints

133 lints with 92 quick fixes, all enabled by default as warnings. Each rule links to its full documentation with examples and fix details.

| Category | Rules | Description |
|----------|------:|-------------|
| [Class Naming](https://nikoro.github.io/many_lints/docs/rules/class-naming/) | 3 | Class and type naming conventions |
| [Bloc / Riverpod](https://nikoro.github.io/many_lints/docs/rules/bloc-riverpod/) | 10 | BLoC and Riverpod state management patterns |
| [Riverpod State](https://nikoro.github.io/many_lints/docs/rules/riverpod-state/) | 9 | Riverpod-specific state rules |
| [Async Safety](https://nikoro.github.io/many_lints/docs/rules/async-safety/) | 4 | Async/await and state mutation safety |
| [Widget Best Practices](https://nikoro.github.io/many_lints/docs/rules/widget-best-practices/) | 18 | General widget best practices |
| [Widget Replacement](https://nikoro.github.io/many_lints/docs/rules/widget-replacement/) | 13 | Simpler widget alternatives |
| [State Management](https://nikoro.github.io/many_lints/docs/rules/state-management/) | 8 | StatefulWidget and state patterns |
| [Control Flow](https://nikoro.github.io/many_lints/docs/rules/control-flow/) | 15 | Control flow statements and patterns |
| [Collection & Type](https://nikoro.github.io/many_lints/docs/rules/collection-type/) | 18 | Collection and type-related checks |
| [Pattern Matching](https://nikoro.github.io/many_lints/docs/rules/pattern-matching/) | 6 | Dart pattern matching best practices |
| [Type Annotations](https://nikoro.github.io/many_lints/docs/rules/type-annotations/) | 5 | Type annotation conventions |
| [Code Organization](https://nikoro.github.io/many_lints/docs/rules/code-organization/) | 3 | Code structure and organization |
| [Shorthand Patterns](https://nikoro.github.io/many_lints/docs/rules/shorthand-patterns/) | 4 | Dot shorthand syntax patterns |
| [Hook Rules](https://nikoro.github.io/many_lints/docs/rules/hook-rules/) | 4 | Flutter Hooks conventions |
| [Testing Rules](https://nikoro.github.io/many_lints/docs/rules/testing-rules/) | 3 | Testing best practices and matchers |
| [Resource Management](https://nikoro.github.io/many_lints/docs/rules/resource-management/) | 3 | Resource cleanup and disposal |
| [Code Quality](https://nikoro.github.io/many_lints/docs/rules/code-quality/) | 7 | General code quality improvements |

## Available Assists

- **Convert to collection-for**: Converts `.map().toList()` or `.map().toSet()` to collection-for syntax.

## Suppressing Diagnostics

To suppress a specific lint, use comments:

```dart
// ignore: many_lints/prefer_center_over_align
const Align(...);

// ignore_for_file: many_lints/use_bloc_suffix
```

The `many_lints/` prefix is **required**. Unlike SDK lints, a plugin diagnostic is only silenced when the rule name is prefixed with the plugin name, so a bare `// ignore: prefer_center_over_align` has no effect. The prefix is the key used under `plugins:` in `analysis_options.yaml`.

Suppressing by type is also possible via `// ignore: type=lint` (the `type=` form is required, and it silences every lint on that line, SDK ones included).

## Example

See the [`example/`](example/) directory for a Flutter project that demonstrates every lint rule in action. Each file corresponds to a single rule and contains code that triggers the lint.
