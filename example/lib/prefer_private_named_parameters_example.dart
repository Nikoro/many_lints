// ignore_for_file: unused_field

// prefer_private_named_parameters
//
// Warns when a public named parameter only initializes a private field and
// could be a private named parameter (Dart 3.12+).

// ❌ Bad: public parameter exists only to feed the private field
class BadBird {
  final String _petName;
  final int _age;

  // LINT: use `required this._petName` instead
  BadBird({required String petName}) : _petName = petName, _age = 1;

  // LINT: works with defaults too — use `this._age = 1`
  BadBird.aged({int age = 1}) : _age = age, _petName = '';
}

// ✅ Good: private named parameters (callers still pass petName: / age:)
class GoodBird {
  final String _petName;
  final int _age;

  GoodBird({required this._petName, this._age = 1});
}

// ✅ Good: parameter is used beyond the initializer, so the boilerplate
// is genuinely needed
class ValidatedBird {
  final String _petName;

  ValidatedBird({required String petName})
    : assert(petName != ''),
      _petName = petName;
}

// ✅ Good: types differ — `this._level` would change the parameter type
class LeveledBird {
  final num _level;

  LeveledBird({required int level}) : _level = level;
}
