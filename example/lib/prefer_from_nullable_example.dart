// ignore_for_file: unused_element, unused_local_variable

// prefer_from_nullable
//
// `Option.fromNullable` makes exactly the decision the conditional spells out.
// The manual form also names the value twice — in the test and in the `Some` —
// which is where the copy-paste bug lives.

import 'package:fpdart/fpdart.dart';

// ❌ Bad: this is Option.fromNullable, written out
// LINT: replace with Option.fromNullable(name)
Option<String> badNotEqualNull(String? name) =>
    name != null ? Option.of(name) : Option<String>.none();

// ❌ Bad: the inverted spelling is the same thing
// LINT: replace with Option.fromNullable(name)
Option<String> badEqualNull(String? name) =>
    name == null ? Option<String>.none() : Option.of(name);

// ✅ Good: one call, the value named once
Option<String> goodFromNullable(String? name) => Option.fromNullable(name);

// ✅ Good: the shorthand for the same constructor
Option<String> goodOptionOf(String? name) => optionOf(name);

// ✅ Good: the Some branch wraps a *different* value, so this is not a
// fromNullable in disguise — rewriting it would change behaviour
Option<String> goodDifferentValue(String? name, String other) =>
    name != null ? Option.of(other) : Option<String>.none();

// ✅ Good: not a null check at all
Option<String> goodOtherCondition(String name) =>
    name.isNotEmpty ? Option.of(name) : Option<String>.none();

// ✅ Good: a plain nullable conditional, no Option involved
String goodPlainDart(String? name) => name != null ? name : 'fallback';
