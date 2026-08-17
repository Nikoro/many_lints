// ignore_for_file: unused_local_variable
// ignore_for_file: many_lints/prefer_returning_shorthands

// avoid_nested_shorthands
//
// Warns when a dot shorthand appears inside the arguments of another dot
// shorthand invocation.
//
// A single shorthand is readable because the declaration next to it names the
// type. Nesting removes that anchor: the inner types come from the outer
// constructor's signature, which is not visible at the call site.

class SomeClass {
  final String value;

  const SomeClass(this.value);

  static const SomeClass empty = SomeClass('');
}

class Some {
  final SomeClass version;

  const Some({required this.version});

  static const Some blank = Some(version: SomeClass(''));
}

class Another {
  final Some some;

  Another(this.some);

  factory Another.of(Some some) => Another(some);

  static Another make(Some some) => Another(some);
}

void badExamples() {
  // LINT x3: every level is a `.new`, so nothing on the line names a type.
  // Reported on `.new(version: .new('val'))`, `.new('val')` — each by its own
  // direct parent.
  final Another a = .new(.new(version: .new('val')));

  // LINT: `.blank` is a property-access shorthand nested in a constructor
  // shorthand. Its type comes from `Another`'s parameter list.
  final Another b = .new(.blank);

  // LINT: static method shorthands nest just as poorly as constructors.
  final Another c = .make(.blank);

  // LINT: so do factory constructor shorthands.
  final Another d = .of(.blank);

  // LINT: the nested shorthand does not have to be a direct argument — `.blank`
  // here sits behind a property access, inside an explicit constructor call.
  final Another e = .new(Some(version: .empty));
}

void goodExamples() {
  // The outer shorthand still drops `Another`; inner types are named.
  final Another a = .new(Some(version: SomeClass('val')));

  // Naming the outer type is equally fine — only nesting is flagged.
  final b = Another(.new(version: SomeClass('val')));

  final Another c = .new(Some.blank);

  // Sibling shorthands are not nested, so they are not flagged.
  final Some d = .blank;
  final Another e = .new(d);

  // A shorthand inside a plain (non-shorthand) constructor call is fine.
  final f = Some(version: .empty);

  // No shorthands at all.
  final g = Another(Some(version: SomeClass('val')));
}
// ignore_for_file: many_lints/member_ordering
// ignore_for_file: many_lints/prefer_declaring_const_constructor
