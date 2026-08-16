// prefer_prefixed_global_constants
//
// Detects a PUBLIC top-level constant without the configured prefix. A global
// constant competes with every local, so the prefix makes its origin visible.
//
//   prefer_prefixed_global_constants:
//     prefix: k

// ❌ Bad: reads identically to a local at the point of use
// LINT: the global constant 'defaultTimeout' does not start with 'k'
const defaultTimeout = 30;

// ✅ Good
const kDefaultTimeout = 30;

// Edge cases where the lint intentionally does NOT trigger

// A private constant cannot collide outside its library.
const _internalTimeout = 30;

// Only constants are checked.
final computedTimeout = 30;
