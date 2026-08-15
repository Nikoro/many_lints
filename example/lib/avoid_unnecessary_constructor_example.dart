// ignore_for_file: unused_element
// ignore_for_file: many_lints/prefer_primary_constructors

// avoid_unnecessary_constructor
//
// Warns when a class declares an empty unnamed constructor identical to the
// one Dart provides when no constructor is written.

// ❌ Bad: exactly the default constructor, spelled out
class BadRepository {
  // LINT: Dart provides this constructor already
  BadRepository();
}

// ❌ Bad: an empty body says the same as `;`
class BadService {
  // LINT: still the default constructor
  BadService() {}
}

// ✅ Good: no constructor at all
class GoodRepository {}

// ✅ Good: `const` lets callers write `const GoodValue()`
class GoodValue {
  const GoodValue();
}

// ✅ Good: it takes a parameter
class GoodHolder {
  const GoodHolder(this.value);

  final int value;
}

// ✅ Edge case: with a second constructor present, the unnamed one has to be
// declared — Dart only supplies it when no constructor is written at all.
class GoodPair {
  GoodPair();

  GoodPair.named();
}

// ✅ Edge case: a documented constructor carries information even when empty.
class GoodDocumented {
  /// Creates an empty instance, which the cache uses as a placeholder.
  GoodDocumented();
}
