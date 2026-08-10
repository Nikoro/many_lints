import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
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
/// Writing `preset: all` into the test package puts each rule back in the
/// state these tests were written for — on, everywhere, unconfigured — so a
/// test exercises the rule's own logic rather than the enablement gate. The
/// gate itself is covered end-to-end in `presets_test.dart` and
/// `rule_config_test.dart`, which drive a real `PluginServer`.
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
    newFile('$testPackageRootPath/${ConfigLoader.fileName}', 'preset: all\n');
  }
}
