// ignore_for_file: unused_element

// prefer_match_file_name
//
// Detects a file whose name does not match the first public declaration in it.
// `user_repository.dart` should declare `class UserRepository`.
//
// Only the FIRST public declaration is checked: a file legitimately holds
// several (a class plus its extension, a sealed hierarchy), and only one of
// them can name the file.

// ❌ Bad
// LINT: the first public declaration is `SomethingElse`, but the file is named
// prefer_match_file_name_example.dart
class SomethingElse {}

// ✅ Good
// A file named user_repository.dart declaring:
//
//   class UserRepository {}
//
// The rest of the declarations in a file are not reported — only the first
// public one names the file.
class AnotherThing {}

// Edge case: a private declaration is skipped when looking for the name, so a
// file opening with `_Helper` is judged by the first PUBLIC declaration after
// it.
class _Helper {}

// Edge case: a part file is exempt entirely. Its name belongs to the composite
// it is part of (`_header.dart` inside `profile_page/`), not to its own
// declaration.

// Edge case: an ENTRYPOINT is a name the language or a framework demands, so it
// can never name the file. `main` is the language's own — every test file has
// one, and none of them can be `main.dart`. `onRequest` and `middleware` are
// dart_frog's route contract, where the file's PATH is the API. Add your own
// with `additional_entrypoints`.
void main() {}
