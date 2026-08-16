// ignore_for_file: unused_element, unused_field

// prefer_named_parameters
//
// Detects a declaration taking more than a few positional parameters.
//
//   prefer_named_parameters:
//     max_positional: 2
//     ignored_names: [main, onRequest, middleware]
//     ignore_private_constructors: true

// ❌ Bad
// LINT: `move(3, 4, 5)` tells the reader nothing, and swapping two arguments
// of the same type compiles cleanly and fails at runtime.
void move(int x, int y, int z) {}

// ✅ Good
void moveNamed({required int x, required int y, required int z}) {}

// Edge case: one or two positional parameters are usually the subject of the
// call, so naming them is noise.
String slice(String value, int start) => value;

// Edge case: a PRIVATE constructor is not an API. It is reached from one place
// in the same library, usually a factory assembling injected dependencies, and
// naming those adds ceremony at the one call site that already knows the order.
class Pipeline {
  const Pipeline._(this._storage, this._adapter, this._policy);

  final String _storage;
  final String _adapter;
  final String _policy;
}

// Edge case: a framework dictates this signature — dart_frog's route contract
// passes the URL's path segments in order, so naming them is not the author's
// to decide.
void onRequest(Object context, String organizerId, String leagueId) {}
