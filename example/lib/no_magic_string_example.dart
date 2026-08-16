// ignore_for_file: unused_element

// no_magic_string
//
// Detects the same string literal repeated without a name.
//
//   no_magic_string:
//     min_occurrences: 3
//     min_length: 3
//     ignore_tests: true

// ❌ Bad
// LINT: reported at EVERY occurrence — each is separately editable, and
// showing only the first would hide the duplication the rule is about. A
// header written out at three call sites will be changed at two of them.
void get_() => _send('x-request-id');
void post() => _send('x-request-id');
void put() => _send('x-request-id');

// ✅ Good
const requestIdHeader = 'x-request-id';

void getNamed() => _send(requestIdHeader);
void postNamed() => _send(requestIdHeader);
void putNamed() => _send(requestIdHeader);

// Edge case: a SINGLE occurrence is silent. It is usually a message or a
// label, and naming it moves the text away from the code that uses it.
void greet() => _send('Welcome back');

// Edge case: short strings are separators and punctuation rather than
// identifiers, so they stay below `min_length`.
String join3(String a, String b, String c) => '$a, $b, $c';

void _send(String value) {}
