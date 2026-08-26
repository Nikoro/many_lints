import 'type_checker.dart';

/// TypeChecker for `Mock`, the base of a generated or hand-written mock.
///
/// Both mocking libraries in common use declare their own `Mock`, so this
/// matches either: `package:mocktail/src/mocktail.dart#Mock` and
/// `package:mockito/src/mock.dart#Mock`.
///
/// `Mock` overrides `==` and `hashCode` so that identity is the instance —
/// which is what `verify()` matches on. A mock comparing its fields instead
/// would break verification, so it is exactly the kind of class that must not
/// be asked to override equality.
const mockChecker = TypeChecker.any([
  TypeChecker.fromUrl('package:mocktail/src/mocktail.dart#Mock'),
  TypeChecker.fromUrl('package:mockito/src/mock.dart#Mock'),
]);

/// TypeChecker for `Fake`, the "implement only what the test touches" base.
///
/// Declared in `package:test_api` and re-exported by `mocktail`; the URL pins
/// where it is *declared*, so the re-export is matched too.
///
/// Unlike [mockChecker], `Fake` itself overrides nothing. A `Fake` subclass
/// reaches this rule through the **interface it implements** —
/// `class _FakePerson extends Fake implements Person {}` inherits `Person`'s
/// `==` through `allSupertypes`. Asking that class to override equality is
/// asking a stand-in with no fields to compare fields it does not have.
const fakeChecker = TypeChecker.fromUrl(
  'package:test_api/src/frontend/fake.dart#Fake',
);
