// ignore_for_file: many_lints/avoid_commented_out_code, many_lints/prefer_primary_constructors, many_lints/require_mirror_test

// require_mirror_test
//
// Warns when a library under `lib/` has no matching test file:
//
//   lib/src/core/version.dart   ->   test/src/core/version_test.dart
//   lib/parser.dart             ->   test/parser_test.dart
//
// The rule is in no preset — it must be enabled by name. This file suppresses
// it, since the example package has no mirrored test tree.

// ❌ Bad: a public class in `lib/` with no test file beside it.
//
// Reported once, at the top of the file:
//
//   lib/src/core/version.dart   ->   no test/src/core/version_test.dart
class Version {
  const Version(this.major, this.minor);

  final int major;
  final int minor;
}

// ✅ Good: create `test/<mirrored path>_test.dart`.
//
//   void main() {
//     test('parses a two-part version', () {
//       expect(Version.parse('1.2'), equals(const Version(1, 2)));
//     });
//   }
//
// `fallback_anywhere` is on by default, so a file of the right name anywhere
// under `test/` also satisfies the rule — reorganising the tree does not turn
// this into noise.

// Edge cases the rule skips without being asked:
//
// - Generated files: `.g.dart`, `.freezed.dart`, anything under `generated/`.
// - Barrels — detected from the AST, since a barrel is not always named after
//   its directory. A file that exports *and* declares is not a barrel.
// - Files declaring nothing public, like the one below: there is no surface a
//   test could target, and demanding one produces empty test files.
class _Cache {
  const _Cache();
}

void _helper() {}
