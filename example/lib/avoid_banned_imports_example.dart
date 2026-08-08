// ignore_for_file: unused_import

// avoid_banned_imports
//
// Warns when a file imports a library banned for its location. The rule
// reports nothing until you configure it — see the `avoid_banned_imports`
// entry in example/many_lints.yaml, which bans 'dart:io' in this file to
// stand in for a domain layer that must stay platform-independent.

// LINT: 'dart:io' is banned here, so this code could not target the web.
import 'dart:io';

// OK: not named by any entry. `deny:` matches exactly, so banning 'dart:io'
// leaves every other library alone.
import 'dart:async';

// Good: depend on an abstraction this layer owns, and let an outer layer be
// the one that imports the platform library and implements it.
abstract class ConfigSource {
  Future<String> read();
}

class UserRepository {
  const UserRepository(this._config);

  final ConfigSource _config;

  Future<String> load() => _config.read();
}
