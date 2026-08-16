// ignore_for_file: unused_element

// prefer_correct_type_name
//
// Detects a type name that is too short, too long, or does not start with a
// capital letter. The defaults are loose (3 to 40 characters) so only genuine
// outliers report.
//
//   prefer_correct_type_name:
//     min_length: 4
//     max_length: 32
//     ignored_names: [Id, Db]

// ❌ Bad
// LINT: shorter than 3 characters — reads as a type parameter at the call site
class Ab {}

// LINT: longer than 40 characters — names its whole call chain
class AVeryLongTypeNameThatDescribesItsEntireCallChain {}

// ✅ Good
class UserRepository {}

// Edge case: a type PARAMETER is exempt. `T`, `E` and `K`/`V` are the SDK's own
// convention, and holding them to a minimum length would fight it.
class Box<T>(final T value);

// Edge case: the leading underscore of a private type is not part of the name a
// reader judges, so `_Foo` is measured as `Foo`.
class _Foo {}
