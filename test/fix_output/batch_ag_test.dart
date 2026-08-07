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

  const sizedBoxWidgets = r'''
class Widget {}
class Key {}
class SizedBox extends Widget {
  const SizedBox({Key? key, double? width, double? height, Widget? child});
  const SizedBox.square({Key? key, double? dimension, Widget? child});
}
class Text extends Widget {
  const Text(String data);
}
''';

  group('prefer_sized_box_square', () {
    test('replaces width/height with dimension', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
Widget f() {
  return SizedBox(height: 10, width: 10);
}
''',
        'prefer_sized_box_square',
        packages: {'flutter': sizedBoxWidgets},
      );

      expect(fixed, contains('SizedBox.square(dimension: 10)'));
      expect(fixed, isNot(contains('width:')));
      expect(fixed, isNot(contains('height:')));
    });
  });

  group('prefer_switch_expression', () {
    test('converts a return-based switch to a switch expression', () async {
      final fixed = await harness.applyFix(r'''
String getType(int value) {
  switch (value) {
    case 1:
      return 'first';
    case 2:
      return 'second';
  }
  return 'default';
}
''', 'prefer_switch_expression');

      expect(fixed, contains('return switch (value) {'));
    });
  });

  const textRichWidgets = r'''
class Widget {}
class InlineSpan {}
class TextSpan extends InlineSpan {
  const TextSpan({String? text, List<InlineSpan>? children, dynamic style});
}
class RichText extends Widget {
  const RichText({required InlineSpan text, dynamic key});
}
class Text extends Widget {
  const Text(String data, {dynamic key});
  const Text.rich(InlineSpan textSpan, {dynamic key});
}
''';

  group('prefer_text_rich', () {
    test('replaces RichText with Text.rich', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
Widget f() {
  return RichText(text: TextSpan(text: 'Hello'));
}
''',
        'prefer_text_rich',
        packages: {'flutter': textRichWidgets},
      );

      expect(fixed, contains("Text.rich(TextSpan(text: 'Hello'))"));
    });
  });

  const themeModeWidgets = r'''
enum ThemeMode {
  system,
  light,
  dark;

  bool get isSystem => this == ThemeMode.system;
  bool get isLight => this == ThemeMode.light;
  bool get isDark => this == ThemeMode.dark;
}
''';

  group('prefer_theme_mode_getters', () {
    test('replaces == ThemeMode.dark with .isDark', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';

bool isDarkMode(ThemeMode mode) => mode == ThemeMode.dark;
''',
        'prefer_theme_mode_getters',
        packages: {'flutter': themeModeWidgets},
      );

      expect(
        fixed,
        contains('bool isDarkMode(ThemeMode mode) => mode.isDark;'),
      );
    });

    test('replaces != ThemeMode.light with negated .isLight', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';

bool notLight(ThemeMode mode) => mode != ThemeMode.light;
''',
        'prefer_theme_mode_getters',
        packages: {'flutter': themeModeWidgets},
      );

      expect(
        fixed,
        contains('bool notLight(ThemeMode mode) => !mode.isLight;'),
      );
    });

    test('handles the constant appearing on the left side', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';

bool isSystem(ThemeMode mode) => ThemeMode.system == mode;
''',
        'prefer_theme_mode_getters',
        packages: {'flutter': themeModeWidgets},
      );

      expect(
        fixed,
        contains('bool isSystem(ThemeMode mode) => mode.isSystem;'),
      );
    });
  });

  group('prefer_type_over_var', () {
    test('replaces var with the inferred type for a local variable', () async {
      final fixed = await harness.applyFix(r'''
void fn() {
  var x = 42;
}
''', 'prefer_type_over_var');

      expect(fixed, contains('int x = 42;'));
    });
  });

  const hooksPackages = {
    'flutter': r'''
class Widget {}
class BuildContext {}
class StatelessWidget extends Widget {
  Widget build(BuildContext context) => Widget();
}
''',
    'flutter_hooks': r'''
import 'package:flutter/flutter.dart';
class HookWidget extends Widget {
  Widget build(BuildContext context) => Widget();
}
T useState<T>(T initialData) => initialData;
T useMemoized<T>(T Function() valueBuilder, [List<Object?>? keys]) =>
    valueBuilder();
T useCallback<T extends Function>(T callback, [List<Object?>? keys]) =>
    callback;
''',
  };

  group('prefer_use_callback', () {
    test('rewrites useMemoized returning a closure into useCallback', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter_hooks/flutter_hooks.dart';
void fn() {
  useMemoized(() => () {});
}
''',
        'prefer_use_callback',
        packages: hooksPackages,
      );

      expect(fixed, contains('useCallback(() {})'));
      expect(fixed, isNot(contains('useMemoized')));
    });

    test('preserves the keys argument', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter_hooks/flutter_hooks.dart';
void myMethod() {}
void fn() {
  useMemoized(() => myMethod, []);
}
''',
        'prefer_use_callback',
        packages: hooksPackages,
      );

      expect(fixed, contains('useCallback(myMethod, [])'));
    });

    test('unwraps a block body with a single return statement', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter_hooks/flutter_hooks.dart';
void fn() {
  useMemoized(() { return () {}; });
}
''',
        'prefer_use_callback',
        packages: hooksPackages,
      );

      expect(fixed, contains('useCallback(() {})'));
    });
  });

  group('prefer_use_prefix', () {
    test('adds the use prefix to a top-level function name', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter_hooks/flutter_hooks.dart';
String myCustomHook() {
  return useMemoized(() => 'hello');
}
''',
        'prefer_use_prefix',
        packages: hooksPackages,
      );

      expect(fixed, contains('String useMyCustomHook() {'));
    });

    test(
      'adds the use prefix to a private function, keeping the underscore',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter_hooks/flutter_hooks.dart';
int _myPrivateHook() {
  return useState(0);
}
''',
          'prefer_use_prefix',
          packages: hooksPackages,
        );

        expect(fixed, contains('int _useMyPrivateHook() {'));
      },
    );

    test('adds the use prefix to a method name', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter_hooks/flutter_hooks.dart';
class MyClass {
  int getCounter() {
    return useState(0);
  }
}
''',
        'prefer_use_prefix',
        packages: hooksPackages,
      );

      expect(fixed, contains('int useGetCounter() {'));
    });
  });

  group('prefer_void_callback', () {
    test(
      'replaces void Function() with VoidCallback and imports dart:ui',
      () async {
        final fixed = await harness.applyFix(r'''
void foo(void Function() callback) {}
''', 'prefer_void_callback');

        expect(fixed, contains("import 'dart:ui';"));
        expect(fixed, contains('void foo(VoidCallback callback) {}'));
      },
    );

    test('preserves nullability with VoidCallback?', () async {
      final fixed = await harness.applyFix(r'''
class MyWidget {
  final void Function()? onTap;
  const MyWidget(this.onTap);
}
''', 'prefer_void_callback');

      expect(fixed, contains('final VoidCallback? onTap;'));
    });
  });

  group('prefer_wildcard_pattern', () {
    test('replaces Object() with _ in a switch expression', () async {
      final fixed = await harness.applyFix(r'''
String f(Object object) {
  return switch (object) {
    int() => 'int',
    Object() => 'other',
  };
}
''', 'prefer_wildcard_pattern');

      expect(fixed, contains("_ => 'other',"));
      expect(fixed, isNot(contains('Object()')));
    });

    test('replaces Object() with _ in an if-case pattern', () async {
      final fixed = await harness.applyFix(r'''
void f(Object object) {
  if (object case Object()) {}
}
''', 'prefer_wildcard_pattern');

      expect(fixed, contains('if (object case _) {}'));
    });
  });

  group('proper_super_calls', () {
    const stateWidgets = r'''
class BuildContext {}

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
  void initState() {}
  void dispose() {}
  void activate() {}
  void deactivate() {}
  void didUpdateWidget(covariant T oldWidget) {}
  void didChangeDependencies() {}
  void reassemble() {}
  Widget build(BuildContext context);
}
''';

    test('moves super.initState() to be the first statement', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String _data = '';

  @override
  void initState() {
    _data = 'Hello';
    super.initState();
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
        'proper_super_calls',
        packages: {'flutter': stateWidgets},
      );

      final initState = fixed.substring(
        fixed.indexOf('void initState()'),
        fixed.indexOf('@override', fixed.indexOf('void initState()')),
      );
      expect(
        initState.trim().startsWith(
          'void initState() {\n    super.initState();',
        ),
        isTrue,
      );
    });

    test('moves super.dispose() to be the last statement', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void dispose() {
    super.dispose();
    print('cleanup');
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
        'proper_super_calls',
        packages: {'flutter': stateWidgets},
      );

      final disposeStart = fixed.indexOf('void dispose()');
      final disposeEnd = fixed.indexOf('}', disposeStart);
      final disposeBody = fixed.substring(disposeStart, disposeEnd);
      expect(disposeBody, contains("print('cleanup');"));
      expect(
        disposeBody.trim().endsWith("print('cleanup');\n    super.dispose();"),
        isTrue,
      );
    });
  });

  group('prefer_transform_over_container', () {
    const transformWidgets = r'''
class Widget {}
class Key {}
class AlignmentGeometry {}
class Matrix4 {
  static Matrix4 identity() => Matrix4._();
  Matrix4._();
}
class Container extends Widget {
  Container({Key? key, Matrix4? transform, AlignmentGeometry? alignment, Widget? child, double? width, double? height});
}
class Transform extends Widget {
  Transform({Key? key, required Matrix4 transform, Widget? child});
}
''';

    test('replaces Container with Transform', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
Widget f() {
  return Container(transform: Matrix4.identity());
}
''',
        'prefer_transform_over_container',
        packages: {'flutter': transformWidgets},
      );

      expect(fixed, contains('Transform(transform: Matrix4.identity())'));
      expect(fixed, isNot(contains('Container(')));
    });
  });
}
