// ignore_for_file: many_lints/avoid_commented_out_code

// avoid_todo_comments
//
// Warns when a comment marks work that was never done without naming a
// tracked issue. `require_reference` is on by default.

// ❌ Bad: markers nobody else can follow up on
Future<void> bad() async {
  await put();
  // TODO: handle the 409 conflict case
  // FIXME: this retries forever
  // HACK: works around the broken header
  // XXX: do not ship this
}

// A username says who has context, not that the work is tracked.
// TODO(dominik): handle the 409 conflict case
void alsoBad() {}

// ✅ Good: each marker names something a person can look up
Future<void> good() async {
  await put();
  // TODO(#42): handle the 409 conflict case
  // TODO: handle this, https://github.com/example/repo/issues/42
  // TODO(PROJ-118): handle the 409 conflict case
}

// Edge cases: not reported.
//
// Prose that mentions a marker is not a marker:
// The TODO above explains why this is ordered as it is.
//
// Neither is a word that merely begins with one:
// TODOS.md lists the remaining work.
// HACKATHON notes live in the wiki.
void edgeCases() {}

Future<void> put() async {}
