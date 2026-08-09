// ignore_for_file: unused_element, unused_local_variable, avoid_print

// avoid_missing_completer_stack_trace
//
// Warns when Completer.completeError is called without a stack trace inside a
// catch block that binds one. The trace is in scope and discarding it makes
// the error surface with a stack that points into async plumbing instead of
// the line that actually threw.

import 'dart:async';

// ❌ Bad: the bound stack trace is discarded
void bad(Completer<void> completer) {
  try {
    throw 'boom';
  } catch (e, st) {
    print(st);
    // LINT: `st` is in scope but not forwarded
    completer.completeError(e);
  }
}

// ❌ Bad: same problem in a typed catch
void badTyped(Completer<int> completer) {
  try {
    throw 'boom';
  } on String catch (e, st) {
    print(st);
    // LINT: a typed catch binds a trace just the same
    completer.completeError(e);
  }
}

// ✅ Good: the trace is passed through
void good(Completer<void> completer) {
  try {
    throw 'boom';
  } catch (e, st) {
    completer.completeError(e, st);
  }
}

// ✅ Edge case: a bare catch binds no trace, so there is nothing to pass
void bareCatch(Completer<void> completer) {
  try {
    throw 'boom';
  } catch (e) {
    completer.completeError(e);
  }
}

// ✅ Edge case: outside a catch block the caller may have no trace at all
void outsideCatch(Completer<void> completer, Object error) {
  completer.completeError(error);
}
