// Support file for avoid_banned_exports_example.dart.
//
// Stands in for an implementation detail that must not reach consumers.

/// An internal cache no consumer should depend on.
class InternalCache {
  final _entries = <String, String>{};

  String? operator [](String key) => _entries[key];

  void operator []=(String key, String value) => _entries[key] = value;
}
