// record_fields_ordering
//
// Detects a record type whose NAMED fields are not in the configured order.
// Positional fields are identified by position, so reordering them would make
// a different type.
//
//   record_fields_ordering:
//     order: alphabetical

// ❌ Bad
// LINT: the field 'code' is out of order
typedef BadResult = ({String message, int code});

// ✅ Good
typedef GoodResult = ({int code, String message});

// Edge cases: a positional record is left alone, and a single named field
// cannot be inconsistent with anything.
typedef Positional = (int, String, bool);
typedef Single = ({int code});
