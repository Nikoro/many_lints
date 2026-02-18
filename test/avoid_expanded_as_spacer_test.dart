import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_expanded_as_spacer.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidExpandedAsSpacerTest));
}

@reflectiveTest
class AvoidExpandedAsSpacerTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidExpandedAsSpacer();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Key {
  const Key(String value);
}

abstract class Widget {
  const Widget({Key? key});
}

class Flex extends Widget {
  const Flex({
    super.key,
    required List<Widget> children,
  });
}

class Column extends Flex {
  const Column({super.key, required super.children});
}

class Row extends Flex {
  const Row({super.key, required super.children});
}

class Expanded extends Widget {
  final int flex;
  final Widget child;
  const Expanded({super.key, this.flex = 1, required this.child});
}

class SizedBox extends Widget {
  final double? width;
  final double? height;
  final Widget? child;
  const SizedBox({super.key, this.width, this.height, this.child});
  const SizedBox.shrink({super.key, this.child}) : width = 0, height = 0;
}

class Container extends Widget {
  final double? width;
  final double? height;
  final Widget? child;
  const Container({super.key, this.width, this.height, this.child});
}

class Spacer extends Widget {
  final int flex;
  const Spacer({super.key, this.flex = 1});
}

class Text extends Widget {
  final String data;
  const Text(this.data, {super.key});
}
''');
    super.setUp();
  }

  // --- Cases that SHOULD trigger the lint ---

  Future<void> test_expandedWithEmptySizedBox() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
final widget = Expanded(child: SizedBox());
''',
      [lint(54, 27)],
    );
  }

  Future<void> test_expandedWithConstEmptySizedBox() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
final widget = const Expanded(child: SizedBox());
''',
      [lint(54, 33)],
    );
  }

  Future<void> test_expandedWithEmptyContainer() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
final widget = Expanded(child: Container());
''',
      [lint(54, 28)],
    );
  }

  Future<void> test_expandedWithFlexAndEmptySizedBox() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
final widget = Expanded(flex: 2, child: SizedBox());
''',
      [lint(54, 36)],
    );
  }

  Future<void> test_expandedWithKeyAndEmptySizedBox() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
final widget = Expanded(key: Key('k'), child: SizedBox());
''',
      [lint(54, 42)],
    );
  }

  Future<void> test_expandedWithSizedBoxWithOnlyKey() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
final widget = Expanded(child: SizedBox(key: Key('k')));
''',
      [lint(54, 40)],
    );
  }

  // --- Cases that should NOT trigger the lint ---

  Future<void> test_expandedWithText() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
final widget = Expanded(child: Text('hello'));
''');
  }

  Future<void> test_expandedWithSizedBoxWithWidth() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
final widget = Expanded(child: SizedBox(width: 10));
''');
  }

  Future<void> test_expandedWithSizedBoxWithHeight() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
final widget = Expanded(child: SizedBox(height: 10));
''');
  }

  Future<void> test_expandedWithSizedBoxWithChild() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
final widget = Expanded(child: SizedBox(child: Text('hi')));
''');
  }

  Future<void> test_expandedWithContainerWithWidth() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
final widget = Expanded(child: Container(width: 10));
''');
  }

  Future<void> test_spacer() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
final widget = Spacer();
''');
  }
}
