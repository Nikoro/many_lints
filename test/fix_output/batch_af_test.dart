import 'package:test/test.dart';

import '../fix_harness.dart';

/// End-to-end tests for the text these quick fixes actually produce.
///
/// See [FixHarness] for why this drives a real plugin server.
void main() {
  late FixHarness harness;

  setUp(() async {
    harness = FixHarness();
    await harness.setUp();
  });

  tearDown(() async {
    await harness.tearDown();
  });

  const flutterBloc = r'''
class BuildContext {}
class Key {}
class Widget {}

class BlocBase<State> {
  BlocBase(State initialState);
}
class Cubit<State> extends BlocBase<State> {
  Cubit(super.initialState);
}

class BlocProvider<T extends BlocBase> extends Widget {
  final T Function(BuildContext) create;
  final Widget child;
  const BlocProvider({Key? key, required this.create, required this.child});
}

class MultiBlocProvider extends Widget {
  final List<BlocProvider> providers;
  final Widget child;
  const MultiBlocProvider({Key? key, required this.providers, required this.child});
}

class RepositoryProvider<T> extends Widget {
  final T Function(BuildContext) create;
  final Widget child;
  const RepositoryProvider({Key? key, required this.create, required this.child});
}

class MultiRepositoryProvider extends Widget {
  final List<RepositoryProvider> providers;
  final Widget child;
  const MultiRepositoryProvider({Key? key, required this.providers, required this.child});
}
''';

  const containerPadding = r'''
class Widget {}
class Key {}
class EdgeInsets {
  const EdgeInsets.all(double value);
}
class Container extends Widget {
  Container({Key? key, EdgeInsets? padding, EdgeInsets? margin, Widget? child});
}
class Padding extends Widget {
  Padding({Key? key, required EdgeInsets padding, Widget? child});
}
''';

  const shorthandGeometry = r'''
class Widget {}

class EdgeInsets {
  const EdgeInsets.all(double value);
  const EdgeInsets.symmetric({double vertical = 0, double horizontal = 0});
}

class Padding extends Widget {
  Padding({required EdgeInsets padding});
}
''';

  const stateWidgets = r'''
class BuildContext {
  bool get mounted => true;
}

class Widget {
  const Widget({Key? key});
}

class Key {}

class StatefulWidget extends Widget {
  const StatefulWidget({super.key});
  State createState() => throw UnimplementedError();
}

abstract class State<T extends StatefulWidget> {
  BuildContext get context => BuildContext();
  bool get mounted => true;
  void setState(void Function() fn) {}
  Widget build(BuildContext context);
}
''';

  group('prefer_multi_bloc_provider', () {
    test('merges nested BlocProviders into MultiBlocProvider', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter_bloc/flutter_bloc.dart';

class BlocA extends Cubit<int> { BlocA() : super(0); }
class BlocB extends Cubit<int> { BlocB() : super(0); }

final provider = BlocProvider<BlocA>(
  create: (context) => BlocA(),
  child: BlocProvider<BlocB>(
    create: (context) => BlocB(),
    child: Widget(),
  ),
);
''',
        'prefer_multi_bloc_provider',
        packages: {'flutter_bloc': flutterBloc},
      );

      expect(fixed, contains('MultiBlocProvider(\n'));
      expect(fixed, contains('providers: ['));
      expect(
        fixed,
        contains('BlocProvider<BlocA>(create: (context) => BlocA())'),
      );
      expect(
        fixed,
        contains('BlocProvider<BlocB>(create: (context) => BlocB())'),
      );
      expect(fixed, contains('child: Widget(),\n)'));
    });

    test(
      'merges nested RepositoryProviders into MultiRepositoryProvider',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter_bloc/flutter_bloc.dart';

class RepoA {}
class RepoB {}

final provider = RepositoryProvider<RepoA>(
  create: (context) => RepoA(),
  child: RepositoryProvider<RepoB>(
    create: (context) => RepoB(),
    child: Widget(),
  ),
);
''',
          'prefer_multi_bloc_provider',
          packages: {'flutter_bloc': flutterBloc},
        );

        expect(fixed, contains('MultiRepositoryProvider('));
        expect(
          fixed,
          contains('RepositoryProvider<RepoA>(create: (context) => RepoA())'),
        );
        expect(
          fixed,
          contains('RepositoryProvider<RepoB>(create: (context) => RepoB())'),
        );
      },
    );
  });

  group('prefer_overriding_parent_equality', () {
    test('generates both == and hashCode overrides', () async {
      final fixed = await harness.applyFix(r'''
class Parent {
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other);
}

class Child extends Parent {
  final String value;
  Child(this.value);
}
''', 'prefer_overriding_parent_equality');

      expect(fixed, contains('bool operator ==(Object other) {'));
      expect(
        fixed,
        contains('return other is Child &&\n        value == other.value;'),
      );
      expect(fixed, contains('int get hashCode => value.hashCode;'));
    });

    test(
      'only generates the missing override when equals already exists',
      () async {
        final fixed = await harness.applyFix(r'''
class Parent {
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other);
}

class Child extends Parent {
  final String value;
  Child(this.value);

  @override
  bool operator ==(Object other) =>
      other is Child && value == other.value;
}
''', 'prefer_overriding_parent_equality');

        expect(fixed, contains('int get hashCode => value.hashCode;'));
        // Only one operator== should remain (the original, untouched).
        expect(
          RegExp(r'operator ==').allMatches(fixed).length,
          2, // one in Parent, one in Child (the original)
        );
      },
    );

    test('generates a hashCode without fields for a class with none', () async {
      final fixed = await harness.applyFix(r'''
class Parent {
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other);
}

class Child extends Parent {}
''', 'prefer_overriding_parent_equality');

      expect(fixed, contains('int get hashCode => runtimeType.hashCode;'));
      expect(fixed, contains('return other is Child;'));
    });
  });

  group('prefer_padding_over_container', () {
    test('replaces a Container using only padding with Padding', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
Widget f() {
  return Container(padding: EdgeInsets.all(8));
}
''',
        'prefer_padding_over_container',
        packages: {'flutter': containerPadding},
      );

      expect(fixed, contains('return Padding(padding: EdgeInsets.all(8));'));
      expect(fixed, isNot(contains('Container')));
    });

    test(
      'replaces a Container using only margin, renaming margin to padding',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter/flutter.dart';
Widget f() {
  return Container(margin: EdgeInsets.all(8));
}
''',
          'prefer_padding_over_container',
          packages: {'flutter': containerPadding},
        );

        expect(fixed, contains('return Padding(padding: EdgeInsets.all(8));'));
        expect(fixed, isNot(contains('margin')));
      },
    );
  });

  group('prefer_private_named_parameters', () {
    test('converts a required named parameter to this._field', () async {
      final fixed = await harness.applyFix(r'''
class Bird {
  final String _petName;
  Bird({required String petName}) : _petName = petName;
}
''', 'prefer_private_named_parameters');

      expect(fixed, contains('Bird({required this._petName});'));
      expect(fixed, isNot(contains('petName = petName')));
    });

    test('preserves a default value on an optional parameter', () async {
      final fixed = await harness.applyFix(r'''
class Bird {
  final int _age;
  Bird({int age = 1}) : _age = age;
}
''', 'prefer_private_named_parameters');

      expect(fixed, contains('Bird({this._age = 1});'));
    });

    test('removes only the matching initializer when others remain', () async {
      final fixed = await harness.applyFix(r'''
class Bird {
  final String _name;
  final int _age;
  Bird({required String name, required int age})
    : _name = name,
      _age = age;
}
''', 'prefer_private_named_parameters');

      expect(fixed, contains('required this._name'));
      expect(fixed, contains('_age = age'));
      expect(fixed, isNot(contains('_name = name,')));
    });
  });

  group('prefer_return_await', () {
    test('adds await to a returned Future in a catch clause', () async {
      final fixed = await harness.applyFix(r'''
Future<String> f() async {
  try {
    throw Exception();
  } catch (e) {
    return asyncOp();
  }
}

Future<String> asyncOp() async => 'result';
''', 'prefer_return_await');

      expect(fixed, contains('return await asyncOp();'));
    });

    test('adds await to a returned Future in the try body', () async {
      final fixed = await harness.applyFix(r'''
Future<String> f() async {
  try {
    return asyncOp();
  } catch (e) {
    return 'fallback';
  }
}

Future<String> asyncOp() async => 'result';
''', 'prefer_return_await');

      expect(fixed, contains('return await asyncOp();'));
    });

    test('adds await to a returned FutureOr in a try body', () async {
      final fixed = await harness.applyFix(r'''
import 'dart:async';

Future<int> f() async {
  try {
    return getFutureOr();
  } catch (e) {
    return -1;
  }
}

FutureOr<int> getFutureOr() => 42;
''', 'prefer_return_await');

      expect(fixed, contains('return await getFutureOr();'));
    });
  });

  group('prefer_returning_shorthands', () {
    test('replaces a default constructor call with a dot shorthand', () async {
      final fixed = await harness.applyFix(r'''
class SomeClass {
  const SomeClass(String value);
}

SomeClass getInstance() => SomeClass('val');
''', 'prefer_returning_shorthands');

      expect(fixed, contains("SomeClass getInstance() => .new('val');"));
    });

    test('replaces a named constructor call with a dot shorthand', () async {
      final fixed = await harness.applyFix(r'''
class SomeClass {
  const SomeClass.named(String value);
}

SomeClass getInstance() => SomeClass.named('val');
''', 'prefer_returning_shorthands');

      expect(fixed, contains("SomeClass getInstance() => .named('val');"));
    });

    test(
      'replaces a static-method constructor call parsed as MethodInvocation',
      () async {
        final fixed = await harness.applyFix(r'''
class SomeClass {
  const SomeClass._(String value);
  static SomeClass named(String value) => ._(value);
}

SomeClass getInstance() => SomeClass.named('val');
''', 'prefer_returning_shorthands');

        expect(fixed, contains("SomeClass getInstance() => .named('val');"));
      },
    );
  });

  group('prefer_shorthands_with_constructors', () {
    test('replaces EdgeInsets.all in an argument position', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';

Widget f() {
  return Padding(padding: EdgeInsets.all(8));
}
''',
        'prefer_shorthands_with_constructors',
        packages: {'flutter': shorthandGeometry},
      );

      expect(fixed, contains('return Padding(padding: .all(8));'));
    });

    test('replaces EdgeInsets.symmetric in a named argument', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';

Widget f() {
  return Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12));
}
''',
        'prefer_shorthands_with_constructors',
        packages: {'flutter': shorthandGeometry},
      );

      expect(
        fixed,
        contains(
          'return Padding(padding: .symmetric(horizontal: 16, vertical: 12));',
        ),
      );
    });
  });

  group('prefer_shorthands_with_enums', () {
    test('replaces an enum prefix in a switch case', () async {
      final fixed = await harness.applyFix(r'''
enum MyEnum { first, second }

void fn(MyEnum? e) {
  switch (e) {
    case MyEnum.first:
      print(e);
    default:
      break;
  }
}
''', 'prefer_shorthands_with_enums');

      expect(fixed, contains('case .first:'));
      expect(fixed, isNot(contains('MyEnum.first')));
    });

    test('replaces an enum prefix in a variable declaration', () async {
      final fixed = await harness.applyFix(r'''
enum MyEnum { first, second }

void fn() {
  final MyEnum another = MyEnum.first;
}
''', 'prefer_shorthands_with_enums');

      expect(fixed, contains('final MyEnum another = .first;'));
    });

    test('replaces an enum prefix on the left side of a comparison', () async {
      final fixed = await harness.applyFix(r'''
enum MyEnum { first, second }

void fn(MyEnum? e) {
  if (MyEnum.first == e) {}
}
''', 'prefer_shorthands_with_enums');

      expect(fixed, contains('if (.first == e) {}'));
    });
  });

  group('prefer_shorthands_with_static_fields', () {
    test(
      'replaces a class prefix on a static field in a variable declaration',
      () async {
        final fixed = await harness.applyFix(r'''
class SomeClass {
  final String value;
  const SomeClass(this.value);
  static const first = SomeClass('first');
  static const second = SomeClass('second');
}

void fn() {
  final SomeClass another = SomeClass.first;
}
''', 'prefer_shorthands_with_static_fields');

        expect(fixed, contains('final SomeClass another = .first;'));
      },
    );

    test(
      'replaces a class prefix on a static field in a switch case',
      () async {
        final fixed = await harness.applyFix(r'''
class SomeClass {
  final String value;
  const SomeClass(this.value);
  static const first = SomeClass('first');
  static const second = SomeClass('second');
}

void fn(SomeClass? e) {
  switch (e) {
    case SomeClass.first:
      print(e);
    default:
      break;
  }
}
''', 'prefer_shorthands_with_static_fields');

        expect(fixed, contains('case .first:'));
        expect(fixed, isNot(contains('SomeClass.first')));
      },
    );
  });

  group('prefer_simpler_patterns_null_check', () {
    test(
      'rewrites an untyped binding to the nullable-pattern shorthand',
      () async {
        final fixed = await harness.applyFix(r'''
void f(String? s) {
  if (s case != null && final field) {}
}
''', 'prefer_simpler_patterns_null_check');

        expect(fixed, contains('if (s case final field?) {}'));
      },
    );

    test(
      'drops the redundant null check when a type annotation is present',
      () async {
        final fixed = await harness.applyFix(r'''
void f(String? s) {
  if (s case != null && final String field) {}
}
''', 'prefer_simpler_patterns_null_check');

        expect(fixed, contains('if (s case final String field) {}'));
      },
    );

    test('rewrites a var binding to the nullable-pattern shorthand', () async {
      final fixed = await harness.applyFix(r'''
void f(String? s) {
  if (s case != null && var field) {}
}
''', 'prefer_simpler_patterns_null_check');

      expect(fixed, contains('if (s case var field?) {}'));
    });
  });

  group('prefer_single_setstate', () {
    test('merges two consecutive setState calls into one', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String _a = '';
  String _b = '';

  void _update() {
    setState(() {
      _a = 'Hello';
    });
    setState(() {
      _b = 'World';
    });
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
        'prefer_single_setstate',
        packages: {'flutter': stateWidgets},
      );

      expect(fixed, contains("_a = 'Hello';"));
      expect(fixed, contains("_b = 'World';"));
      expect(RegExp(r'setState\(').allMatches(fixed).length, 1);
    });

    test(
      'merges three setState calls, dropping the second and third statements',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter/flutter.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String _a = '';
  String _b = '';
  String _c = '';

  void _update() {
    setState(() {
      _a = 'Hello';
    });
    setState(() {
      _b = 'World';
    });
    setState(() {
      _c = '!';
    });
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
          'prefer_single_setstate',
          packages: {'flutter': stateWidgets},
        );

        expect(fixed, contains("_a = 'Hello';"));
        expect(fixed, contains("_b = 'World';"));
        expect(fixed, contains("_c = '!';"));
        expect(RegExp(r'setState\(').allMatches(fixed).length, 1);
      },
    );
  });
}
