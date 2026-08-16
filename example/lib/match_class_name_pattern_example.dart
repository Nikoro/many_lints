// match_class_name_pattern
//
// Detects a class name that does not match the configured pattern. This is the
// general form of use_class_prefix / use_class_suffix.
//
//   match_class_name_pattern:
//     pattern: '[A-Z][A-Za-z0-9]*Page'

// ❌ Bad
// LINT: the class name 'Home' does not match the pattern
class Home {}

// ✅ Good
class HomePage {}

// Edge case: the pattern must match the WHOLE name, so a prefix match is not
// enough.
// LINT: 'HomePageExtra' matches only a prefix
class HomePageExtra {}
