// ignore_for_file: unused_element

// avoid_unnecessary_return
//
// Warns when a bare `return;` is the last statement of a function that
// returns nothing.

// ❌ Bad: nothing follows the `return`
void badTrailingReturn(int value) {
  _record(value);
  // LINT: control leaves the function here anyway
  return;
}

// ❌ Bad: same in a method
class BadExamples {
  void process(int value) {
    _record(value);
    // LINT: last statement of a void method
    return;
  }
}

// ❌ Bad: an async function returning Future<void>
Future<void> badAsyncReturn(int value) async {
  _record(value);
  // LINT: last statement of a Future<void> function
  return;
}

// ✅ Good: no `return` at all
void goodPlain(int value) {
  _record(value);
}

// ✅ Good: the `return` skips the statements below it
void goodEarlyReturn(int value) {
  if (value < 0) return;
  _record(value);
}

// ✅ Edge case: a `return` carrying a value is a different thing entirely.
int goodValueReturn(int value) {
  return value * 2;
}

void _record(int value) {}
