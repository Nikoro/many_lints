// ignore_for_file: many_lints/prefer_immutable_state
// prefer_correct_error_name
//
// Detects an exception or error class not named with the matching suffix.
// The name is where "should I catch this?" is answered at the call site.

// ❌ Bad: the call site cannot tell which kind it is
// LINT: 'NotFound' is an exception but does not end with 'Exception'
class NotFound implements Exception {}

// LINT: 'BadState' is an error but does not end with 'Error'
class BadState extends Error {}

// ✅ Good
class NotFoundException implements Exception {}

class BadStateError extends Error {}

// Edge cases where the lint intentionally does NOT trigger

// An ordinary class is never considered.
class Widget {}

// A class that is both is named for the stricter reading: an Error is a bug
// the caller must not catch.
class WeirdError extends Error implements Exception {}

// The suffix is inherited through the hierarchy, so an indirect subclass is
// still checked against it.
class TimeoutException extends NotFoundException {}
