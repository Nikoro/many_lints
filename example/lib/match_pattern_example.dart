// match_pattern
//
// Reports code matching a project-supplied pattern, and offers the project's
// own replacement as a quick fix. Reports nothing until configured.
//
//   match_pattern:
//     patterns:
//       - find: '^unawaited\((.+)\)$'
//         replace: '$1.unawaited()'
//         message: 'Prefer the trailing form from many_extensions.'
//         in: ['lib/**']

void unawaited(Object? future) {}

Object? refresh() => 'done';

// ❌ Bad
void bad() {
  // LINT: matches the configured pattern; the fix rewrites it to the
  // trailing form.
  unawaited(refresh());
}

// ✅ Good
void good() {
  refresh().unawaited();
}

extension on Object? {
  void unawaited() {}
}

// Edge case: the pattern is anchored to the whole node, so a substring does
// not match. With `find: 'awaited\(1\)'` the call below is NOT reported.
void anchored() {
  unawaited(1);
}

// Edge case: matching is textual, so a call split across lines does not match
// a pattern written on one line.
void formatting() {
  unawaited(refresh());
}

// Edge case: an entry with no `replace:` reports only. Nothing is ever
// rewritten unless the pattern asked for it.
