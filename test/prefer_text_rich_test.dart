import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_text_rich.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferTextRichTest));
}

@reflectiveTest
class PreferTextRichTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferTextRich();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {}
class InlineSpan {}
class TextSpan extends InlineSpan {
  const TextSpan({String? text, List<InlineSpan>? children, dynamic style});
}
class RichText extends Widget {
  const RichText({required InlineSpan text, dynamic key});

  static RichText create({required InlineSpan text}) =>
      RichText(text: text);
}
class Text extends Widget {
  const Text(String data, {dynamic key});
  const Text.rich(InlineSpan textSpan, {dynamic key});
}
''');
    super.setUp();
  }

  Future<void> test_richText_basic() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return RichText(text: TextSpan(text: 'Hello'));
}
''',
      [lint(61, 8)],
    );
  }

  Future<void> test_richText_with_children() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return RichText(
    text: TextSpan(
      text: 'Hello ',
      children: [
        TextSpan(text: 'bold'),
        TextSpan(text: ' world!'),
      ],
    ),
  );
}
''',
      [lint(61, 8)],
    );
  }

  Future<void> test_richText_with_key() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return RichText(key: null, text: TextSpan(text: 'Hello'));
}
''',
      [lint(61, 8)],
    );
  }

  Future<void> test_richText_const() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return const RichText(text: TextSpan(text: 'Hello'));
}
''',
      [lint(67, 8)],
    );
  }

  Future<void> test_textRich_no_lint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Text.rich(TextSpan(text: 'Hello'));
}
''');
  }

  Future<void> test_text_no_lint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Text('Hello');
}
''');
  }

  // --- MethodInvocation path (top-level function returning RichText) ---

  Future<void> test_methodInvocation_richText() async {
    // makeRichText() is a MethodInvocation with staticType=RichText and
    // target=null. The RichText() in the function body also triggers the lint.
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
RichText makeRichText({required InlineSpan text}) =>
    RichText(text: text);
final w = makeRichText(text: TextSpan(text: 'Hello'));
''',
      [lint(96, 8), lint(128, 12)],
    );
  }

  Future<void> test_methodInvocation_richText_withTarget_noLint() async {
    // Factory.make() has target=Factory, so visitMethodInvocation skips it.
    // The RichText() in the method body still triggers through visitInstanceCreationExpression.
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
class Factory {
  static RichText make({required InlineSpan text}) =>
      RichText(text: text);
}
final w = Factory.make(text: TextSpan(text: 'Hello'));
''',
      [lint(115, 8)],
    );
  }
}
