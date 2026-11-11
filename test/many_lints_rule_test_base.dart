// ignore_for_file: implementation_imports

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:many_lints/src/rule_config.dart';

export 'package:analyzer_testing/analysis_rule/analysis_rule.dart';

/// Base class for this package's rule tests.
///
/// Rules are opt-in as of 1.0.0: [ManyLintsRule] discards a rule's diagnostics
/// unless the package under analysis selected a preset or configured the rule
/// by name. A rule test constructs its rule directly and writes no
/// configuration, so without this base class every one of them would assert
/// against a rule that has been switched off.
///
/// Writing an explicit `enabled: true` for the rule under test puts it back in
/// the state these tests were written for — on and unconfigured — so a test
/// exercises the rule's own logic rather than the enablement gate. An explicit
/// `enabled:` is step 1 of [ManyLintsConfig.isRuleEnabled], so this holds for
/// every rule regardless of which preset happens to contain it. The gate
/// itself is covered end-to-end in `presets_test.dart` and
/// `rule_config_test.dart`, which drive a real `PluginServer`.
///
/// Naming the rule explicitly rather than selecting a broad preset also means
/// a rule deliberately left out of every preset — a `banned_*` rule, or one
/// half of a contradictory pair — is still testable here.
///
/// A test that needs different configuration writes its own `many_lints.yaml`
/// over this one, since [setUp] runs before the test body.
abstract class ManyLintsRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    super.setUp();

    // The loader caches per package root keyed on the file's modification
    // stamp, and every test reuses the same in-memory root, so a stale entry
    // from the previous test would otherwise win.
    ConfigLoader.clearCache();
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n  ${rule.name}: true\n',
    );
  }
}

/// Expects the analyzer's own error for a name that does not resolve.
///
/// analyzer 14.6 replaced `undefined_method`, `undefined_getter`,
/// `undefined_function`, `undefined_identifier` and `undefined_prefixed_name`
/// with one read and one write diagnostic per lookup kind. The package accepts
/// analyzer 14.5 (Dart 3.11) and 14.7, so a fixture that leans on a gap in the
/// mock SDK matches either spelling.
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
