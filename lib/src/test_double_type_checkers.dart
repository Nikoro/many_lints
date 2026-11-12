import 'type_checker.dart';

const mockChecker = TypeChecker.any([
  TypeChecker.fromUrl('package:mocktail/src/mocktail.dart#Mock'),
  TypeChecker.fromUrl('package:mockito/src/mock.dart#Mock'),
]);

const fakeChecker = TypeChecker.fromUrl(
  'package:test_api/src/frontend/fake.dart#Fake',
);
