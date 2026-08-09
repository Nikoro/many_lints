// ignore_for_file: unused_element, unused_local_variable, avoid_print
// `var` counters and an explicit callback type keep the loop shapes readable.
// ignore_for_file: many_lints/prefer_type_over_var
// ignore_for_file: many_lints/prefer_void_callback

// avoid_unmodified_loop_condition
//
// Warns when a while loop's condition reads only variables the body never
// assigns. The condition evaluates the same way forever, so the loop either
// never runs or never stops.

// ❌ Bad: the counter is never advanced
void badNeverAdvanced(int limit) {
  var i = 0;
  // LINT: nothing in the body can change `i`
  while (i < limit) {
    print(i);
  }
}

// ❌ Bad: the wrong variable is advanced
void badWrongVariable(int limit) {
  var i = 0;
  var j = 0;
  // LINT: `j` moves, but the condition reads `i`
  while (i < limit) {
    j++;
  }
}

// ❌ Bad: a do/while has the same hazard
void badDoWhile(int limit) {
  var i = 0;
  do {
    print(i);
    // LINT: the condition can never become false
  } while (i < limit);
}

// ✅ Good: the counter advances
void goodAdvanced(int limit) {
  var i = 0;
  while (i < limit) {
    i++;
  }
}

// ✅ Good: a compound assignment counts as a modification
void goodCompound(int limit) {
  var i = 0;
  while (i < limit) {
    i += 2;
  }
}

// ✅ Good: `while (true)` with a break is the idiomatic infinite loop
void goodWhileTrue(List<int> items) {
  while (true) {
    if (items.isEmpty) break;
    items.removeLast();
  }
}

// ✅ Edge case: a method call may observe outside change each iteration
void opaqueCondition(List<int> items) {
  while (items.isNotEmpty) {
    items.removeLast();
  }
}

// ✅ Edge case: a field can be changed by anything the body calls
class Runner {
  bool running = true;

  void go() {
    while (running) {
      stop();
    }
  }

  void stop() {
    running = false;
  }
}

// ✅ Edge case: a closure may mutate what it captures when invoked
void closurePresent(int limit, void Function(void Function()) run) {
  var i = 0;
  while (i < limit) {
    run(() {
      i++;
    });
  }
}
