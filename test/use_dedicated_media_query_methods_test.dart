import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/use_dedicated_media_query_methods.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
      () => defineReflectiveTests(UseDedicatedMediaQueryMethodsTest));
}

@reflectiveTest
class UseDedicatedMediaQueryMethodsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseDedicatedMediaQueryMethods();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class BuildContext {}
class Size {
  final double width;
  final double height;
  const Size(this.width, this.height);
}
class EdgeInsets {
  static const EdgeInsets zero = EdgeInsets.all(0);
  const EdgeInsets.all(double value);
}
class Orientation { static const portrait = Orientation._(); const Orientation._(); }
class MediaQueryData {
  final Size size;
  final Orientation orientation;
  final double devicePixelRatio;
  final double textScaleFactor;
  final EdgeInsets padding;
  final EdgeInsets viewInsets;
  final EdgeInsets viewPadding;
  const MediaQueryData({
    this.size = const Size(0, 0),
    this.orientation = Orientation.portrait,
    this.devicePixelRatio = 1.0,
    this.textScaleFactor = 1.0,
    this.padding = EdgeInsets.zero,
    this.viewInsets = EdgeInsets.zero,
    this.viewPadding = EdgeInsets.zero,
  });
}
class MediaQuery {
  static MediaQueryData of(BuildContext context) => MediaQueryData();
  static MediaQueryData? maybeOf(BuildContext context) => MediaQueryData();
  static Size sizeOf(BuildContext context) => const Size(0, 0);
}
''');
    super.setUp();
  }

  Future<void> test_mediaQueryOfSize() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
void f(BuildContext context) {
  MediaQuery.of(context).size;
}
''',
      [lint(72, 27)],
    );
  }

  Future<void> test_mediaQueryOfOrientation() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
void f(BuildContext context) {
  MediaQuery.of(context).orientation;
}
''',
      [lint(72, 34)],
    );
  }

  Future<void> test_mediaQueryMaybeOfSize() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
void f(BuildContext context) {
  MediaQuery.maybeOf(context)?.size;
}
''',
      [lint(72, 33)],
    );
  }

  Future<void> test_mediaQuerySizeOf() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
void f(BuildContext context) {
  MediaQuery.sizeOf(context);
}
''');
  }

  Future<void> test_mediaQueryOfAssignedToVariable() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
void f(BuildContext context) {
  final data = MediaQuery.of(context);
}
''');
  }
}
