// Support file for avoid_banned_exports_example.dart.
//
// Stands in for a library that is deliberately part of the public API.

/// A type consumers are meant to depend on.
class ApiClient {
  const ApiClient(this.baseUrl);

  final String baseUrl;
}
