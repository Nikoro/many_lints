// ignore_for_file: unused_element
// ignore_for_file: many_lints/prefer_typedefs_for_callbacks

// prefer_explicit_parameter_names
//
// Detects a function type declaring unnamed parameters.
//
//   prefer_explicit_parameter_names:
//     min_parameters: 2

// ❌ Bad
// LINT: at the point where someone writes this callback, `(String, int)` gives
// them two anonymous values to guess at — is the int an index, a count, an id?
typedef OnChangedBad = void Function(String, int);

// ✅ Good: IDEs echo these names into the closure they generate.
typedef OnChanged = void Function(String label, int count);

// A function-typed PARAMETER is checked the same way.
void listenBad(void Function(String, int) callback) {}

void listen(void Function(String label, int count) callback) {}

// Edge case: a single-parameter function type is unambiguous from the type
// alone, so it is exempt by default. Set `min_parameters: 1` to report it too.
typedef OnTap = void Function(String);
