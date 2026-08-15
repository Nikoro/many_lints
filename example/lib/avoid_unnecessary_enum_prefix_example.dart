// ignore_for_file: unused_element

// avoid_unnecessary_enum_prefix
//
// Warns when an enum constant repeats the name of its own enum, which every
// call site already carries.

// ❌ Bad: every use reads `Status.statusActive`
enum Status {
  // LINT: the enum name is already part of every use
  statusActive,
  // LINT: same here
  statusArchived,
}

// ✅ Good: the type carries the name, the constant carries the value
enum GoodStatus { active, archived }

// ✅ Edge case: a constant named exactly like its enum is the whole word,
// not a prefix.
enum Kind { kind, simple }

// ✅ Edge case: `modal` merely starts with the same letters as `Mode`; the
// prefix has to end at a word boundary.
enum Mode { modal, simple }
