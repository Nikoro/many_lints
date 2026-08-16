// match_lib_folder_structure
//
// Detects a folder under `lib/` whose name is not lower_snake_case.
//
// A folder name becomes part of every `package:` URI that imports through it,
// so it is public API in a way a local variable name is not. `CamelCase` and
// `kebab-case` folders also break on case-insensitive filesystems: a folder
// renamed from `Models` to `models` is invisible to git on macOS, and the
// import keeps resolving locally while failing in CI.
//
// The SDK's `file_names` rule checks the FILE; nothing in the SDK checks the
// directories above it, which is the gap this fills.

// ❌ Bad
//
//   lib/dataSources/user_repository.dart   → LINT: 'dataSources' is not
//                                            lower_snake_case
//   lib/data-sources/user_repository.dart  → LINT: 'data-sources' likewise
//
// The diagnostic is anchored at the top of the file and reported once per
// file, at the first offending folder: a second one on the same path would be
// fixed by the same rename.

// ✅ Good
//
//   lib/data_sources/user_repository.dart
//
// This example file sits directly in `lib/`, so it has no folder to report —
// the rule is demonstrated by the paths above rather than by this file's own
// location.
class UserRepository {}
