import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/use_sliver_prefix.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(UseSliverPrefixTest));
}

@reflectiveTest
class UseSliverPrefixTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseSliverPrefix();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {
  const Widget({Key? key});
}
class Key {}
class BuildContext {}
class StatelessWidget extends Widget {
  const StatelessWidget({super.key});
  Widget build(BuildContext context) => Widget();
}
class StatefulWidget extends Widget {
  const StatefulWidget({super.key});
  State createState();
}
class State<T extends StatefulWidget> {
  T get widget => throw '';
  void setState(void Function() fn) {}
  Widget build(BuildContext context) => Widget();
}
class Container extends Widget {
  const Container({super.key, Widget? child});
}
class Text extends Widget {
  const Text(String data, {super.key});
}
class SliverToBoxAdapter extends Widget {
  const SliverToBoxAdapter({super.key, Widget? child});
}
class SliverList extends Widget {
  const SliverList({super.key});
}
class SliverAppBar extends StatefulWidget {
  const SliverAppBar({super.key});
  @override
  State<SliverAppBar> createState() => _SliverAppBarState();
}
class _SliverAppBarState extends State<SliverAppBar> {
  @override
  Widget build(BuildContext context) => Widget();
}
class SliverPadding extends Widget {
  const SliverPadding({super.key, Widget? sliver});
}
class CustomScrollView extends Widget {
  const CustomScrollView({super.key, List<Widget>? slivers});
}
''');
    super.setUp();
  }

  // --- Cases that SHOULD trigger the lint ---

  Future<void> test_statelessWidgetReturningSliverToBoxAdapter_lint() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyAdapter extends StatelessWidget {
  const MyAdapter({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: Text('hello'));
  }
}
''',
      [lint(46, 9)],
    );
  }

  Future<void> test_statelessWidgetReturningSliverList_lint() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyList extends StatelessWidget {
  const MyList({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList();
  }
}
''',
      [lint(46, 6)],
    );
  }

  Future<void>
  test_statelessWidgetReturningSliverToBoxAdapter_arrowBody_lint() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyBoxAdapter extends StatelessWidget {
  const MyBoxAdapter({super.key});

  @override
  Widget build(BuildContext context) =>
      SliverToBoxAdapter(child: Text('hi'));
}
''',
      [lint(46, 12)],
    );
  }

  Future<void> test_statefulWidgetStateReturningSliverPadding_lint() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyPadding extends StatefulWidget {
  const MyPadding({super.key});

  @override
  State<MyPadding> createState() => _MyPaddingState();
}

class _MyPaddingState extends State<MyPadding> {
  @override
  Widget build(BuildContext context) {
    return SliverPadding();
  }
}
''',
      [lint(46, 9)],
    );
  }

  // --- Cases that should NOT trigger the lint ---

  Future<void> test_sliverPrefixedClass_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class SliverMyAdapter extends StatelessWidget {
  const SliverMyAdapter({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: Text('hello'));
  }
}
''');
  }

  Future<void> test_widgetReturningNonSliver_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(child: Text('hello'));
  }
}
''');
  }

  Future<void> test_widgetReturningCustomScrollView_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyScrollView extends StatelessWidget {
  const MyScrollView({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView();
  }
}
''');
  }

  Future<void> test_statefulWidgetWithSliverPrefix_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class SliverMyPadding extends StatefulWidget {
  const SliverMyPadding({super.key});

  @override
  State<SliverMyPadding> createState() => _SliverMyPaddingState();
}

class _SliverMyPaddingState extends State<SliverMyPadding> {
  @override
  Widget build(BuildContext context) {
    return SliverPadding();
  }
}
''');
  }

  Future<void> test_classWithoutBuildMethod_noLint() async {
    await assertNoDiagnostics(r'''
class MyHelper {
  String getName() => 'hello';
}
''');
  }
}
