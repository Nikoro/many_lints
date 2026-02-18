import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_incorrect_image_opacity.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidIncorrectImageOpacityTest),
  );
}

@reflectiveTest
class AvoidIncorrectImageOpacityTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidIncorrectImageOpacity();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {
  const Widget({Key? key});
}

class Key {}

class Opacity extends Widget {
  const Opacity({super.key, required double opacity, Widget? child});
}

class Image extends Widget {
  const Image({super.key, String? semanticLabel, Animation<double>? opacity});

  const Image.asset(String name, {Key? key, Animation<double>? opacity});

  const Image.network(String src, {Key? key, Animation<double>? opacity});
}

class Animation<T> {
  const Animation();
}

class AlwaysStoppedAnimation<T> extends Animation<T> {
  const AlwaysStoppedAnimation(T value);
}
''');
    super.setUp();
  }

  Future<void> test_opacityWrappingImage() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Opacity(
    opacity: 0.5,
    child: Image(semanticLabel: 'test'),
  );
}
''',
      [lint(61, 7)],
    );
  }

  Future<void> test_opacityWrappingImageAsset() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Opacity(
    opacity: 0.5,
    child: Image.asset('path/to/image.png'),
  );
}
''',
      [lint(61, 7)],
    );
  }

  Future<void> test_opacityWrappingImageNetwork() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Opacity(
    opacity: 0.5,
    child: Image.network('https://example.com/image.png'),
  );
}
''',
      [lint(61, 7)],
    );
  }

  Future<void> test_opacityWrappingNonImage() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
class Text extends Widget {
  const Text(String data);
}
Widget f() {
  return Opacity(
    opacity: 0.5,
    child: Text('hello'),
  );
}
''');
  }

  Future<void> test_imageWithoutOpacityWrapper() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Image(semanticLabel: 'test');
}
''');
  }

  Future<void> test_imageWithOpacityParameter() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Image(
    semanticLabel: 'test',
    opacity: AlwaysStoppedAnimation(0.5),
  );
}
''');
  }

  Future<void> test_opacityWithNoChild() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Opacity(opacity: 0.5);
}
''');
  }
}
