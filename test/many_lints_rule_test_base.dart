// ignore_for_file: implementation_imports

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:many_lints/src/rule_config.dart';

export 'package:analyzer_testing/analysis_rule/analysis_rule.dart';

abstract class ManyLintsRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    super.setUp();

    // Edge case: the loader caches by modification stamp and every test reuses one package root
    ConfigLoader.clearCache();
    // Edge case: rules are opt-in, so the rule under test is enabled by name, not by a preset
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n  ${rule.name}: true\n',
    );
  }
}

// Edge case: analyzer 14.6 renamed the undefined_* codes and both analyzer lines are supported
ExpectedDiagnostic undefinedName(int offset, int length) => ExpectedDiagnostic(
  (diagnostic) =>
      _undefinedNameCodes.contains(diagnostic.diagnosticCode.lowerCaseName),
  offset,
  length,
);

const _undefinedNameCodes = {
  'undefined_method',
  'undefined_getter',
  'undefined_function',
  'undefined_identifier',
  'undefined_prefixed_name',
  'undefined_instance_member_read',
  'undefined_static_member_read',
  'undefined_unqualified_name_read',
  'undefined_prefixed_name_read',
};
