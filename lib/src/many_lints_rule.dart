import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';

import 'rule_config.dart';

/// Forwards diagnostics into an existing [DiagnosticReporter].
///
/// Needed because [_MessageAppendingReporter] must be constructed with a
/// listener, while the reporter handed to the rule exposes none — so the way
/// back to the driver's own listener is through the reporter's public
/// [DiagnosticReporter.reportError].
class _ForwardingListener implements DiagnosticListener {
  final DiagnosticReporter _target;

  const _ForwardingListener(this._target);

  @override
  void onDiagnostic(Diagnostic diagnostic) => _target.reportError(diagnostic);
}

/// A [DiagnosticReporter] that appends a project-configured sentence to every
/// diagnostic's problem message.
///
/// This sits at the same seam as `exclude`: every `reportAt*` method on
/// [AnalysisRule] funnels through the reporter, and inside the reporter
/// `atNode` / `atToken` / `atSourceRange` all delegate to `atOffset`, which
/// ends at the single public, overridable [reportError]. Overriding that one
/// method therefore catches every diagnostic a rule can emit, so no rule needs
/// code of its own to support `message:`.
///
/// Subclassing is what makes this possible: `DiagnosticReporter` keeps its
/// listener in a private field with no accessor, so a wrapping *listener*
/// cannot be built from an existing reporter — the incoming one is opaque.
///
/// The rebuilt diagnostic keeps the original `diagnosticCode`, so
/// `// ignore: many_lints/<rule>` comments, severity overrides and the fix
/// registry — which is keyed on the code — all keep working. Only the rendered
/// problem message changes.
class _MessageAppendingReporter extends DiagnosticReporter {
  final String _suffix;

  _MessageAppendingReporter(super.listener, super.source, this._suffix);

  @override
  void reportError(Diagnostic diagnostic) {
    final problem = diagnostic.problemMessage;

    super.reportError(
      Diagnostic.forValues(
        source: diagnostic.source,
        offset: problem.offset,
        length: problem.length,
        diagnosticCode: diagnostic.diagnosticCode,
        message: '${problem.messageText(includeUrl: false)} $_suffix',
        correctionMessage: diagnostic.correctionMessage,
        contextMessages: diagnostic.contextMessages,
      ),
    );
  }
}

/// Base class for every rule in this package, adding per-rule `exclude`,
/// `include` and `message` support from `many_lints.yaml` to the stock
/// [AnalysisRule].
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
///
/// The same seam carries the other two universal options. `include` resolves
/// alongside `exclude` in [ResolvedRuleConfig] and reaches the rule as the
/// same null reporter, and `message` swaps in a reporter that rewrites each
/// diagnostic on its way out. All three are therefore free for every rule in
/// the package, including rules written after this comment.
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

  /// The path of the file currently being visited, relative to the package
  /// root and separated by `/`, or `null` when it lies outside the root.
  ///
  /// Rules whose options scope by path (`in:` on a banned entry) match globs
  /// against this. It is captured alongside [config] when the reporter is set,
  /// so like [config] it is only meaningful inside a visitor callback.
  ///
  /// The path comes from the reporter's own source rather than
  /// [RuleContext.currentUnit] so it always names the file being reported on:
  /// [RuleContext.isInLibDir] and `isInTestDirectory` are computed from the
  /// *defining* unit and misreport for part files.
  String? get relativePath => _relativePath;
  String? _relativePath;

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
      _relativePath = null;
      super.reporter = value;
      return;
    }

    final path = value.source.fullName;
    final resolved = ResolvedRuleConfig.forPath(
      packageRoot: root,
      path: path,
      ruleName: name,
    );
    _config = resolved.config;
    // Normalize Windows separators the way analyzer's own exclude handling
    // does, so a single glob spelling works on every platform.
    _relativePath = root.relativeIfContains(path)?.replaceAll(r'\', '/');

    if (resolved.isExcluded) {
      super.reporter = DiagnosticReporter(
        DiagnosticListener.nullListener,
        value.source,
      );
      return;
    }

    final message = resolved.config.message;
    if (message == null) {
      super.reporter = value;
      return;
    }

    // The rewritten diagnostic is handed back to the *original* reporter, via
    // a listener that forwards into it. `DiagnosticReporter` keeps its
    // listener private with no accessor, so the incoming one cannot be
    // unwrapped — but it can still be delegated to.
    super.reporter = _MessageAppendingReporter(
      _ForwardingListener(value),
      value.source,
      message,
    );
  }
}
