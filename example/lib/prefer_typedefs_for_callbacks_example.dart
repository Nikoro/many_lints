// ignore_for_file: unused_element

// prefer_typedefs_for_callbacks
//
// Detects an inline function type that would be clearer as a named typedef.
// Only types with at least `min_parameters` parameters are reported.

// ❌ Bad: the shape is visible, the meaning is not
// LINT: this inline function type has 2 parameters
void badListen(void Function(String, int) onEvent) {}

// ✅ Good: the signature has a name that can be reused and documented
typedef EventHandler = void Function(String name, int code);

void goodListen(EventHandler onEvent) {}

// Edge cases where the lint intentionally does NOT trigger

// Already readable; naming these adds indirection without information.
void noParameters(void Function() callback) {}

void oneParameter(void Function(String) callback) {}
// ignore_for_file: many_lints/prefer_void_callback
