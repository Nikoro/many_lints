import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';

import 'rule_config.dart';

/// Base class for every rule in this package, adding per-rule `exclude`
/// support from `many_lints.yaml` to the stock [AnalysisRule].
///
/// ## Why this intercepts the reporter instead of guarding each visitor
///
/// The obvious implementation resolves [ResolvedRuleConfig] at the top of every
/// visitor callback and returns early when excluded. That works, but it has to
/// be repeated in each registered callback of each rule: 42 of this package's
/// rules register more than one AST callback, and a single missed callback
/// silently leaks diagnostics from an excluded file — a bug no rule's own tests
/// would catch, because they never configure an exclude.
///
/// Every reporting method on [AnalysisRule] (`reportAtNode`, `reportAtToken`,
/// `reportAtOffset`, `reportAtSourceRange`, `reportAtPubNode`) funnels through
/// the single `reporter` field, and both drivers — the analyzer's
/// `LibraryAnalyzer` and `PluginServer` — assign that field once per
/// compilation unit, immediately before visiting it. Overriding the setter
/// therefore gives one interception point per file, which no rule can bypass
/// and no new rule has to remember.
///
/// When the file is excluded the rule is handed a reporter backed by
/// [DiagnosticListener.nullListener], so the rule's visitors still run and
/// still "report" — the diagnostics are simply discarded. Suppressing at the
/// sink rather than skipping the visit keeps this independent of how any
/// individual rule is structured.
abstract class ManyLintsRule extends AnalysisRule {
  ManyLintsRule({required super.name, required super.description, super.state});

  /// The resolved configuration for the file currently being visited.
  ///
  /// Rules that expose options read them from here, e.g.
  /// `config.boolOption('ignore_typed_catches', defaultValue: false)`. It is
  /// [RuleConfig.empty] until the framework sets the first reporter, and is
  /// refreshed for every unit, so it is only meaningful from inside a visitor
  /// callback.
  RuleConfig get config => _config;
  RuleConfig _config = RuleConfig.empty;

  /// The package root of the library currently being analyzed.
  ///
  /// The reporter carries the file being reported on, but not the package that
  /// file belongs to, and [RuleContext] is not passed to the setter — so the
  /// root is captured in [registerNodeProcessors], which both drivers call
  /// once per library before assigning any reporter.
  Folder? _packageRoot;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    _packageRoot = context.package?.root;
    registerManyLintsProcessors(registry, context);
  }

  /// Registers this rule's node processors.
  ///
  /// Subclasses override this instead of [registerNodeProcessors], which is
  /// reserved for capturing the package root before analysis begins.
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  );

  @override
  set reporter(DiagnosticReporter value) {
    final root = _packageRoot;
    if (root == null) {
      _config = RuleConfig.empty;
      super.reporter = value;
      return;
    }

    final resolved = ResolvedRuleConfig.forPath(
      packageRoot: root,
      path: value.source.fullName,
      ruleName: name,
    );
    _config = resolved.config;

    super.reporter = resolved.isExcluded
        ? DiagnosticReporter(DiagnosticListener.nullListener, value.source)
        : value;
  }
}
