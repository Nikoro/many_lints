// ignore_for_file: unused_element

// format_comment
//
// Detects a comment that is not written as a capitalised, terminated sentence.
//
// Only doc comments (///) are checked by default. Set
// `check_regular_comments: true` to include // too.

// ❌ Bad
// LINT: the doc comment below does not start with a capital letter.
/// a user of the system.
class BadLowercase {}

// ❌ Bad
// LINT: the doc comment below does not end with a period.
/// A user of the system
class BadUnterminated {}

/// A user of the system.
class GoodExample {}

/// A user of the system, holding the identity that every other record in
/// the database ultimately points back to.
///
/// The block is the unit: a sentence spanning several lines is capitalised on
/// the first and terminated on the last, so the middle lines are never
/// reported on their own.
class GoodMultiLine {}

/// dart_frog mounts a dynamic route directory before its static siblings.
///
/// Edge case: a bare identifier opening the sentence is exempt. Capitalising
/// `dart_frog` or `runApp` would falsify the name — the same reason a
/// backticked or [bracketed] reference is exempt.
class GoodLeadingIdentifier {}

/// Builds a user.
///
/// Edge case: a fenced code block is not prose.
///
/// ```dart
/// final user = User();
/// ```
class GoodCodeFence {}

/// https://dart.dev/effective-dart/documentation
class GoodBareUrl {}

/// A player, never an account (see `plan.md` section 3.5).
///
/// Edge case: a sentence that MENTIONS a file is still prose. Only a line that
/// is nothing but a URL is exempt.
class GoodSentenceMentioningAFile {}
