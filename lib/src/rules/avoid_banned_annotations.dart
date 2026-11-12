import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../banned_entry.dart';
import '../many_lints_rule.dart';

class AvoidBannedAnnotations extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_banned_annotations',
    "The annotation '@{0}' is banned here.{1}",
    correctionMessage:
        'Remove the annotation or move this code out of the '
        'restricted directory.',
  );

  AvoidBannedAnnotations()
    : super(
        name: 'avoid_banned_annotations',
        description: 'Warns when a banned annotation is used in a file.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addAnnotation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidBannedAnnotations rule;

  _Visitor(this.rule);

  @override
  void visitAnnotation(Annotation node) {
    final entries = readBannedEntries(rule.config);
    if (entries.isEmpty) return;

    final name = switch (node.name) {
      PrefixedIdentifier(:final identifier) => identifier.name,
      final Identifier identifier => identifier.name,
    };
    if (name.isEmpty) return;

    final banned = findBannedEntry(
      entries: entries,
      value: name,
      relativePath: rule.relativePath,
    );
    if (banned == null) return;

    rule.reportAtNode(node, arguments: [name, messageSuffix(banned)]);
  }
}
