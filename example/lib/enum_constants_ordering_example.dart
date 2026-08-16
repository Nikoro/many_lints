// enum_constants_ordering
//
// Detects an enum whose constants are not in the configured order.
// Reports nothing until an `order:` is chosen, which is why this example
// configures one:
//
//   enum_constants_ordering:
//     order: alphabetical

// ❌ Bad: a reader scanning for a name has to check every constant
// LINT: 'apple' is out of order
enum BadFruit { banana, apple, cherry }

// ✅ Good
enum GoodFruit { apple, banana, cherry }

// Edge case: only the FIRST out-of-order constant is reported, because one
// misplaced name makes every later name look wrong too.
// LINT: reported once, on 'apple'
enum PartlyOrdered { zebra, apple, banana, cherry }

// Note that a semantic order is exactly why this rule is opt-in: with no
// `order:` configured, this enum is correct as written.
enum Size { small, medium, large }
