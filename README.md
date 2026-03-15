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
    <img src="https://img.shields.io/badge/coverage-90%25-brightgreen" alt="coverage 90%">
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img alt="MIT License" src="https://tinyurl.com/3uf9tzpy">
  </a>
  <a href="https://pub.dev/packages/analyzer">
    <img src="https://img.shields.io/badge/analyzer-11.0.0-blue" alt="analyzer version 11.0.0">
  </a>
</p>

A useful collection of custom lints for Flutter & Dart projects. Uses the new `analysis_server_plugin` system for direct integration with `dart analyze` and IDEs.

**[Browse all rules on the documentation site](https://nikoro.github.io/many_lints)**

## Getting started

> **Requires Dart 3.10+ (Flutter 3.38+)**

Add `many_lints` to the **top-level** `plugins` section in your `analysis_options.yaml` file (NOT under `analyzer:`):

```yaml
plugins:
  many_lints: ^0.4.0
```

That's it — the analysis server will automatically download and resolve the plugin from [pub.dev](https://pub.dev/packages/many_lints). There is no need to add it to your `pubspec.yaml`.

> **Important**: After any change to the `plugins` section, you must restart the Dart Analysis Server.

For local development setup, see [CONTRIBUTING.md](CONTRIBUTING.md).

### Configuring diagnostics

All rules are registered as warnings and enabled by default. You can enable or disable individual rules under the `diagnostics` key:

```yaml
plugins:
  many_lints:
    version: ^0.4.0
    diagnostics:
      prefer_center_over_align: true
      use_bloc_suffix: false
```

## Available Lints

100 lints with 78 quick fixes, all enabled by default as warnings. Each rule links to its full documentation with examples and fix details.

| Category | Rules | Description |
|----------|------:|-------------|
| [Async Safety](https://nikoro.github.io/many_lints/docs/rules/async-safety/) | 2 | Async/await and state mutation safety |
| [BLoC & Riverpod](https://nikoro.github.io/many_lints/docs/rules/bloc-riverpod/) | 9 | BLoC and Riverpod state management patterns |
| [Class Naming](https://nikoro.github.io/many_lints/docs/rules/class-naming/) | 3 | Class and type naming conventions |
| [Code Organization](https://nikoro.github.io/many_lints/docs/rules/code-organization/) | 3 | Code structure and organization |
| [Code Quality](https://nikoro.github.io/many_lints/docs/rules/code-quality/) | 2 | General code quality improvements |
| [Collections & Types](https://nikoro.github.io/many_lints/docs/rules/collection-type/) | 13 | Collection and type-related checks |
| [Control Flow](https://nikoro.github.io/many_lints/docs/rules/control-flow/) | 11 | Control flow statements and patterns |
| [Hook Rules](https://nikoro.github.io/many_lints/docs/rules/hook-rules/) | 2 | Flutter Hooks conventions |
| [Pattern Matching](https://nikoro.github.io/many_lints/docs/rules/pattern-matching/) | 4 | Dart pattern matching best practices |
| [Resource Management](https://nikoro.github.io/many_lints/docs/rules/resource-management/) | 3 | Resource cleanup and disposal |
| [Riverpod State](https://nikoro.github.io/many_lints/docs/rules/riverpod-state/) | 2 | Riverpod-specific state rules |
| [Shorthand Patterns](https://nikoro.github.io/many_lints/docs/rules/shorthand-patterns/) | 4 | Dot shorthand syntax patterns |
| [State Management](https://nikoro.github.io/many_lints/docs/rules/state-management/) | 6 | StatefulWidget and state patterns |
| [Testing](https://nikoro.github.io/many_lints/docs/rules/testing-rules/) | 4 | Testing best practices and matchers |
| [Type Annotations](https://nikoro.github.io/many_lints/docs/rules/type-annotations/) | 5 | Type annotation conventions |
| [Widget Best Practices](https://nikoro.github.io/many_lints/docs/rules/widget-best-practices/) | 14 | General widget best practices |
| [Widget Replacement](https://nikoro.github.io/many_lints/docs/rules/widget-replacement/) | 13 | Simpler widget alternatives |

## Available Assists

- **Convert to collection-for**: Converts `.map().toList()` or `.map().toSet()` to collection-for syntax.

## Suppressing Diagnostics

To suppress a specific lint, use comments:

```dart
// ignore: many_lints/prefer_center_over_align
const Align(...);

// ignore_for_file: many_lints/use_bloc_suffix
```

## Example

See the [`example/`](example/) directory for a Flutter project that demonstrates every lint rule in action. Each file corresponds to a single rule and contains code that triggers the lint.
