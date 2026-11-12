import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';

import 'rule_config.dart';

class _ForwardingListener implements DiagnosticListener {
  final DiagnosticReporter _target;

  const _ForwardingListener(this._target);

  @override
  void onDiagnostic(Diagnostic diagnostic) => _target.reportError(diagnostic);
}

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

abstract class ManyLintsRule extends AnalysisRule {
  ManyLintsRule({required super.name, required super.description, super.state});

  RuleConfig get config => _config;
  RuleConfig _config = RuleConfig.empty;

  Folder? _packageRoot;

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

  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  );

  @override
  set reporter(DiagnosticReporter value) {
    final root = _packageRoot;
    if (root == null) {
      // Edge case: a file outside any package has no config, so opt-in rules stay silent
      _config = RuleConfig.empty;
      _relativePath = null;
      super.reporter = DiagnosticReporter(
        DiagnosticListener.nullListener,
        value.source,
      );
      return;
    }

    final path = value.source.fullName;
    final resolved = ResolvedRuleConfig.forPath(
      packageRoot: root,
      path: path,
      ruleName: name,
    );
    _config = resolved.config;
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

    // Edge case: DiagnosticReporter hides its listener, so the original one is delegated to
    super.reporter = _MessageAppendingReporter(
      _ForwardingListener(value),
      value.source,
      message,
    );
  }
}
