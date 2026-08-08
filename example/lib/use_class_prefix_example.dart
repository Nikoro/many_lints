// use_class_prefix
//
// Warns when a class deriving from a configured type lacks the required name
// prefix. The rule reports nothing until you configure it — see the
// `use_class_prefix` entry in example/many_lints.yaml, which requires the
// 'Db' prefix for implementations of Repository.
//
// The entry omits `package:`, so it also matches a type declared in this
// package — a pin is only needed to disambiguate a name from a dependency.

abstract class Repository {}

// LINT: implements Repository but does not start with 'Db'
class UserRepository implements Repository {}

// OK: carries the required prefix.
class DbOrderRepository implements Repository {}

// OK: unrelated to any configured type.
class PlainService {}
