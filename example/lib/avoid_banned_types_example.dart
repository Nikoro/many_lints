// ignore_for_file: unused_element
// ignore_for_file: many_lints/prefer_returning_shorthands

// avoid_banned_types
//
// Warns when a banned type is named in a file. The rule reports nothing until
// you configure it — see the `avoid_banned_types` entry in
// example/many_lints.yaml, which bans a deprecated model being retired.

/// The deprecated model.
class LegacyUser {
  const LegacyUser(this.name);

  final String name;
}

/// Its replacement.
class User {
  const User(this.name);

  final String name;
}

// LINT: banned as a parameter type.
void greetLegacy(LegacyUser user) => print(user.name);

// LINT: banned as a return type, and again in the constructor call.
LegacyUser findLegacy() => const LegacyUser('ada');

// LINT: banned as a type argument — every mention counts, not just annotations.
List<LegacyUser> allLegacy() => const [];

// ✅ Good: the replacement type is not banned.
void greet(User user) => print(user.name);

User find() => const User('ada');

List<User> all() => const [User('ada')];

// 🔹 Edge case: matching is on the *declared* name, so an import prefix does
// not hide a usage — `p.LegacyUser` would still report. Qualify an entry as
// `package:uri#Name` when a bare name is ambiguous across packages.
