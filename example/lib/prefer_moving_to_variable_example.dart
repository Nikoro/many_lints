// ignore_for_file: unused_element, unused_local_variable
// ignore_for_file: many_lints/prefer_returning_shorthands
// ignore_for_file: many_lints/use_existing_variable
// ignore_for_file: many_lints/prefer_for_loop_in_children

// prefer_moving_to_variable
//
// Warns when the same property-access or invocation chain is repeated inside
// one block, and could be computed once into a variable.

class _ColorScheme {
  const _ColorScheme();
  int get primary => 0;
  int get secondary => 1;
}

class _TextTheme {
  const _TextTheme();
  int get body => 0;
}

class _Theme {
  const _Theme();

  static _Theme of(Object context) => const _Theme();

  _ColorScheme get colors => const _ColorScheme();
  _TextTheme get text => const _TextTheme();
}

class _Inner {
  const _Inner();
  int get value => 0;
}

class _Outer {
  const _Outer();
  _Inner get inner => const _Inner();
}

// ❌ Bad: the same chain recomputed
int badRepeatedInvocation(Object context) {
  // LINT: '_Theme.of(context)' is repeated 2 times in this block.
  final a = _Theme.of(context).colors.primary;
  final b = _Theme.of(context).text.body;
  return a + b;
}

int badRepeatedPropertyChain(_Outer outer) {
  // LINT: 'outer.inner.value' is repeated 2 times in this block.
  final a = outer.inner.value;
  final b = outer.inner.value;
  return a + b;
}

// ✅ Good: named once, then reused
int goodNamedOnce(Object context) {
  final theme = _Theme.of(context);
  return theme.colors.primary + theme.text.body;
}

// ✅ Good: a single occurrence needs no name
int goodSingleUse(Object context) => _Theme.of(context).colors.primary;

// ✅ Good: one link reads no worse than a variable would, so the default
// `min_chain_length: 2` leaves it alone.
int goodShortChain(_Inner inner) => inner.value + inner.value;

// ✅ Good: a fresh instance every time — reusing one would change behaviour.
int goodInstanceCreation() => const _Inner().value + const _Inner().value;

// ✅ Good: a closure may run any number of times, so the chain cannot be
// hoisted out of it.
List<int> goodInsideClosure(Object context, List<int> items) =>
    items.map((e) => _Theme.of(context).colors.primary).toList();
