// ignore_for_file: unused_local_variable

// prefer_simpler_patterns_null_check
//
// Warns when an if-case pattern uses `!= null && final field` instead of
// the simpler `final field?` syntax, or when a typed binding already
// guarantees non-nullability making the `!= null` redundant.

class WithField {
  final String? field;
  WithField(this.field);
}

// ❌ Bad: Redundant null-check with variable binding
void bad(WithField object) {
  // LINT: Use `final field?` instead
  if (object.field case != null && final field) {
    print(field);
  }

  // LINT: Type annotation already guarantees non-null
  if (object.field case != null && final String field) {
    print(field);
  }
}

// ✅ Good: Simpler patterns
void good(WithField object) {
  // Nullable binding with postfix ?
  if (object.field case final field?) {
    print(field);
  }

  // Typed binding (type already excludes null)
  if (object.field case final String field) {
    print(field);
  }

  // Plain null check only
  if (object.field case != null) {
    print('not null');
  }
}
