import 'package:many_lints/src/rule_config.dart';
import 'package:many_lints/src/rules/prefer_extracting_callbacks.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferExtractingCallbacksTest);
    defineReflectiveTests(PreferExtractingCallbacksThresholdTest);
    defineReflectiveTests(PreferExtractingCallbacksFunctionsTest);
  });
}

const _flutter = r'''
class Widget {
  const Widget({Key? key});
}
class Key {}
class BuildContext {}
class StatelessWidget extends Widget {
  const StatelessWidget({super.key});
  Widget build(BuildContext context) => Widget();
}
class ElevatedButton extends Widget {
  const ElevatedButton({super.key, void Function()? onPressed, Widget? child});
}
class Builder extends Widget {
  const Builder({super.key, Widget Function(BuildContext)? builder});
}
''';

@reflectiveTest
class PreferExtractingCallbacksTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferExtractingCallbacks();
    newPackage('flutter').addFile('lib/widgets.dart', _flutter);
    super.setUp();
  }

  Future<void> test_longInlineCallbackIsReported() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

final button = ElevatedButton(
  onPressed: () {
    print(1);
    print(2);
    print(3);
    print(4);
  },
);
''',
      [lint(84, 64)],
    );
  }

  Future<void> test_shortInlineCallbackIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

final button = ElevatedButton(
  onPressed: () {
    print(1);
  },
);
''');
  }

  Future<void> test_tearOffIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void submit() {}

final button = ElevatedButton(onPressed: submit);
''');
  }

  Future<void> test_functionCallIsSilentByDefault() async {
    await assertNoDiagnostics(r'''
void schedule({void Function()? task}) {}

void run() {
  schedule(
    task: () {
      print(1);
      print(2);
      print(3);
      print(4);
    },
  );
}
''');
  }

  Future<void> test_builderCallbackIsExempt() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

final b = Builder(
  builder: (context) {
    print(1);
    print(2);
    print(3);
    print(4);
    return Widget();
  },
);
''');
  }
}

@reflectiveTest
class PreferExtractingCallbacksThresholdTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferExtractingCallbacks();
    newPackage('flutter').addFile('lib/widgets.dart', _flutter);
    super.setUp();
    ConfigLoader.clearCache();
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n'
          '  prefer_extracting_callbacks:\n'
          '    max_statements: 1\n',
    );
  }

  Future<void> test_loweredThresholdReports() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

final button = ElevatedButton(
  onPressed: () {
    print(1);
    print(2);
  },
);
''',
      [lint(84, 36)],
    );
  }

  Future<void> test_singleStatementIsStillSilent() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

final button = ElevatedButton(
  onPressed: () {
    print(1);
  },
);
''');
  }
}

@reflectiveTest
class PreferExtractingCallbacksFunctionsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferExtractingCallbacks();
    newPackage('flutter').addFile('lib/widgets.dart', _flutter);
    super.setUp();
    ConfigLoader.clearCache();
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n'
          '  prefer_extracting_callbacks:\n'
          '    report_functions: true\n',
    );
  }

  Future<void> test_functionCallReportsWhenEnabled() async {
    await assertDiagnostics(
      r'''
void schedule({void Function()? task}) {}

void run() {
  schedule(
    task: () {
      print(1);
      print(2);
      print(3);
      print(4);
    },
  );
}
''',
      [lint(78, 74)],
    );
  }

  Future<void> test_shortFunctionCallbackIsStillSilent() async {
    await assertNoDiagnostics(r'''
void schedule({void Function()? task}) {}

void run() {
  schedule(
    task: () {
      print(1);
    },
  );
}
''');
  }
}
