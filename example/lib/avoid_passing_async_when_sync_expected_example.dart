// ignore_for_file: unused_element, unused_local_variable
// The explicit function types are the point of this file — the typedef
// suggestions would hide the void-vs-Future distinction being demonstrated.
// ignore_for_file: many_lints/prefer_void_callback
// ignore_for_file: many_lints/prefer_async_callback

// avoid_passing_async_when_sync_expected
//
// Warns when an async closure is passed to a `void Function(...)` parameter.
// The returned Future is assigned to void and dropped, so nothing awaits the
// work and errors inside it become unhandled async errors.

void schedule(void Function() task) {}

void scheduleAsync(Future<void> Function() task) {}

void scheduleDynamic(dynamic Function() task) {}

void build({required void Function() onPressed}) {}

Future<void> save() async {}

void reportError(Object error, StackTrace stackTrace) {}

// ❌ Bad: the future is dropped by the void parameter
void bad() {
  // LINT: nothing awaits this work
  schedule(() async {
    await save();
  });
}

// ❌ Bad: the same through a named parameter
void badNamed() {
  // LINT: `onPressed` is void-returning, so the future is discarded
  build(
    onPressed: () async {
      await save();
    },
  );
}

// ❌ Bad: an arrow body is no different
void badArrow() {
  // LINT: the returned future still goes nowhere
  schedule(() async => save());
}

// ✅ Good: the parameter returns a Future, so the caller can await it
void good() {
  scheduleAsync(() async {
    await save();
  });
}

// ✅ Good: genuinely fire-and-forget, with errors handled inside
void goodHandled() {
  scheduleAsync(() async {
    try {
      await save();
    } catch (e, st) {
      reportError(e, st);
    }
  });
}

// ✅ Good: a synchronous callback has nothing to drop
void goodSync() {
  schedule(() {});
}

// ✅ Edge case: `dynamic` accepts the future as a value the callee may keep
void dynamicReturn() {
  scheduleDynamic(() async {
    await save();
  });
}

// ✅ Edge case: only arguments are checked, not variable assignments
void assignedToVariable() {
  final void Function() task = () async {
    await save();
  };
  task();
}
