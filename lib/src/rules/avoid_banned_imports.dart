import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../banned_entry.dart';
import '../many_lints_rule.dart';

class AvoidBannedImports extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_banned_imports',
    "The import '{0}' is banned here.{1}",
    correctionMessage:
        'Remove the import or move this code out of the '
        'restricted directory.',
  );

  AvoidBannedImports()
    : super(
        name: 'avoid_banned_imports',
        description:
            'Warns when a file imports a library banned for its '
            'location.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidBannedImports rule;

  _Visitor(this.rule);

  @override
  void visitImportDirective(ImportDirective node) {
    // Edge case: rule instances are reused across package roots, so the config cannot be cached
    final entries = readBannedEntries(rule.config);
    if (entries.isEmpty) return;

    final uri = node.uri.stringValue;
    if (uri == null) return;

    final banned = findBannedEntry(
      entries: entries,
      value: uri,
      relativePath: rule.relativePath,
    );
    if (banned == null) return;

    rule.reportAtNode(node.uri, arguments: [uri, messageSuffix(banned)]);
  }
}
