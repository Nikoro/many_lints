// ignore_for_file: unused_element, unused_field

// prefer_boolean_prefixes
//
// Warns when a boolean is named as though it were a value rather than a
// yes-or-no question.

// ❌ Bad: reads as a noun, not a condition
class BadUser {
  // LINT: `if (user.admin)` makes the reader check what `admin` is
  bool admin = false;

  // LINT: a past participle states a fact, it does not ask
  bool emailSent = false;

  // LINT: same for a getter
  bool get visible => true;
}

// ✅ Good: the verb makes it a question at every call site
class GoodUser {
  bool isAdmin = false;

  bool hasSentEmail = false;

  bool get isVisible => true;

  bool canSubmit() => true;
}

// ✅ Edge case: the verb does not have to lead. `localeIsDefault` asks the
// same question as `isDefaultLocale`, and naming the subject first keeps
// related settings sorting together.
class GoodSettings {
  bool localeIsDefault = false;
  bool themeModeIsDefault = false;
}

// ✅ Edge case: a bare third-person verb is already a question.
class GoodFixture {
  bool involves(String playerId) => true;
  bool matches(String query) => true;
}

// ✅ Edge case: an override cannot rename independently, so only the base
// declaration is judged.
class GoodBase {
  bool get isReady => false;
}

class GoodDerived extends GoodBase {
  @override
  bool get isReady => true;
}
// ignore_for_file: many_lints/prefer_getter_over_method
