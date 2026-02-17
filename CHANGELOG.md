# Changelog

## [Unreleased]

### Added

- `avoid_constant_conditions` rule to warn when both sides of a comparison are constants
- `avoid_constant_switches` rule to warn when a switch expression is a constant
- `avoid_contradictory_expressions` rule to detect contradictory comparisons in `&&` chains
- `avoid_duplicate_cascades` rule to detect duplicate cascade sections with quick fix
- `avoid_generics_shadowing` rule to warn when a generic type parameter shadows a top-level declaration with quick fix
- `prefer_simpler_patterns_null_check` rule to prefer simpler null-check patterns in if-case expressions with quick fix

## [0.3.0] - 2026-02-14

### Added

- `prefer_shorthands_with_enums` rule to detect enum values replaceable with shorthand constructors
- `prefer_shorthands_with_constructors` rule to detect constructors replaceable with shorthand syntax
- `prefer_shorthands_with_static_fields` rule to detect static fields replaceable with shorthand syntax
- `prefer_returning_shorthands` rule to detect return statements replaceable with shorthand syntax
- `prefer_switch_expression` rule to suggest using switch expressions over switch statements
- `prefer_explicit_function_type` rule to prefer explicit function types over `Function`
- `prefer_type_over_var` rule to prefer explicit type annotations over `var`
- `prefer_abstract_final_static_class` rule to flag utility classes that should be abstract final
- `prefer_iterable_of` rule to prefer `Iterable.of` over `Iterable.from` for same-type conversions
- `avoid_accessing_collections_by_constant_index` rule to flag hardcoded index access on collections
- `avoid_cascade_after_if_null` rule to detect cascades after if-null operators
- `avoid_collection_equality_checks` rule to flag equality checks on collections
- `avoid_collection_methods_with_unrelated_types` rule to flag collection method calls with unrelated types
- `avoid_commented_out_code` rule to detect commented-out code blocks

### Changed

- Extracted shared utilities, renamed helpers, and refactored suffix rules

## [0.2.1] - 2026-02-05

### Fixed

- Fix invalid dartdoc reference syntax causing pub.dev scoring issues
- Skip example directory in CI workflow

### Added

- README.md for pub.dev Example tab

## [0.2.0] - 2026-02-05

### Added

- `use_gap` rule to prefer `Gap` widget over `SizedBox` or `Padding` for spacing
- Quick fixes for suffix rules (`use_bloc_suffix`, `use_cubit_suffix`, `use_notifier_suffix`)
- Quick fix for `avoid_unnecessary_consumer_widgets` rule
- Example project demonstrating all lint rules
- Dartdoc comments to public APIs

### Changed

- Renamed test methods to snake_case for consistency
- Applied recommended lints from `lints` package

## [0.1.2] - 2026-02-04

### Fixed

- Add `lib/main.dart` re-export for proper `analysis_server_plugin` discovery
- Replace deprecated analyzer API usages with new equivalents

## [0.1.1] - 2026-02-04

### Fixed

- Allow passing arguments to the format command

## [0.1.0] - 2026-02-04

### Added

- `avoid_single_child_in_multi_child_widgets` - detect single-child usage in multi-child widgets
- `avoid_unnecessary_consumer_widgets` - flag unnecessary Riverpod consumer widgets
- `avoid_unnecessary_hook_widgets` - flag unnecessary hook widgets with quick fix
- `prefer_align_over_container` - prefer `Align` over `Container` for alignment only
- `prefer_any_or_every` - prefer `any`/`every` over manual iteration with quick fix
- `prefer_center_over_align` - prefer `Center` over `Align` for centering with quick fix
- `prefer_padding_over_container` - prefer `Padding` over `Container` for padding only with quick fix
- `use_bloc_suffix` - enforce `Bloc` suffix on bloc classes
- `use_cubit_suffix` - enforce `Cubit` suffix on cubit classes
- `use_dedicated_media_query_methods` - prefer dedicated `MediaQuery` methods with quick fix
- `use_notifier_suffix` - enforce `Notifier` suffix on notifier classes
- `convert_iterable_map_to_collection_for` assist
