// ignore_for_file: unused_catch_clause, unused_catch_stack

// avoid_empty_catch
//
// Warns when a catch clause does nothing with the exception it caught.
// Unlike the SDK's `empty_catches`, this also reports `catch (_) {}`
// and a body holding only a comment.

// ❌ Bad: the failure disappears
void bad() {
  // LINT: nothing at all in the body
  try {
    uploadSymbols();
  } catch (e) {}

  // LINT: the SDK's `empty_catches` allows this shape; this rule does not
  try {
    uploadSymbols();
  } catch (_) {}

  // LINT: a comment tells a reader who is already looking at this line
  try {
    uploadSymbols();
  } catch (e) {
    // Ignored, really.
  }

  // LINT: an `on` clause with an empty body is the same defect, narrowed
  try {
    uploadSymbols();
  } on FormatException {}
}

// ✅ Good: the body does something observable
void good() {
  // Log it.
  try {
    uploadSymbols();
  } on FormatException catch (e, s) {
    report('symbol upload failed', e, s);
  }

  // Rethrow after adding context.
  try {
    uploadSymbols();
  } catch (e) {
    report('symbol upload failed', e, null);
    rethrow;
  }
}

// Edge case: an empty *try* body is not an empty catch.
void edgeCase() {
  try {} catch (e) {
    report('failed', e, null);
  }
}

void uploadSymbols() {}

void report(String message, Object error, StackTrace? stackTrace) {}
