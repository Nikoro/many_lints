// avoid_too_many_methods
//
// Detects a class declaring more methods than the configured budget.
// This example lowers the budget to 5 so the file stays readable:
//
//   avoid_too_many_methods:
//     max_methods: 5

// ❌ Bad: one class covering authentication, profiles and export
// LINT: declares more methods than the budget
class UserManager {
  void signIn() {}
  void signOut() {}
  void refreshToken() {}
  void editProfile() {}
  void uploadAvatar() {}
  void exportCsv() {}
}

// ✅ Good: each class has a subject its name can describe
class UserAuthentication {
  void signIn() {}
  void signOut() {}
  void refreshToken() {}
}

class UserProfile {
  void edit() {}
  void uploadAvatar() {}
}

// Edge cases where the lint intentionally does NOT trigger
class DataClass {
  const DataClass(this._a, this._b);

  // Named constructors offer ways to build one thing, not several jobs.
  const DataClass.empty() : _a = 0, _b = 0;
  const DataClass.zero() : _a = 0, _b = 0;
  const DataClass.one() : _a = 1, _b = 1;
  const DataClass.two() : _a = 2, _b = 2;
  const DataClass.three() : _a = 3, _b = 3;
  const DataClass.four() : _a = 4, _b = 4;

  final int _a;
  final int _b;

  // Accessors are the class's surface, not its behaviour.
  int get a => _a;
  int get b => _b;
  int get sum => _a + _b;
  int get difference => _a - _b;
  int get product => _a * _b;
  int get maximum => _a > _b ? _a : _b;
}
