// prefer_any_or_every
//
// Use .any() instead of .where().isNotEmpty
// Use .every() with negated condition instead of .where().isEmpty

class PreferAnyOrEveryExample {
  final List<int> numbers = [1, 2, 3, 4, 5];

  void checkNumbers() {
    // LINT: Use .any() instead of .where().isNotEmpty
    final hasEven = numbers.where((n) => n.isEven).isNotEmpty;

    // LINT: Use .every() instead of .where().isEmpty
    final allPositive = numbers.where((n) => n < 0).isEmpty;

    print('$hasEven $allPositive');
  }
}
