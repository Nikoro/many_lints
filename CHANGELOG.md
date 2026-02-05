# Changelog

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
