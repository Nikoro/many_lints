import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when RichText is used instead of Text.rich.
///
/// RichText does not handle text scaling well. Prefer Text.rich
/// for better accessibility support.
class PreferTextRich extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_text_rich',
    'Use Text.rich instead of RichText for better text scaling and accessibility.',
    correctionMessage: 'Replace RichText with Text.rich.',
  );

  PreferTextRich()
    : super(
        name: 'prefer_text_rich',
        description:
            'Warns when RichText is used instead of Text.rich for better accessibility.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferTextRich rule;

  _Visitor(this.rule);

  static const _richTextChecker = TypeChecker.fromName(
    'RichText',
    packageName: 'flutter',
  );

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.staticType;
    if (type == null || !_richTextChecker.isExactlyType(type)) return;

    rule.reportAtNode(node.constructorName);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final type = node.staticType;
    if (type == null || !_richTextChecker.isExactlyType(type)) return;

    // Only flag direct RichText() calls, not methods on RichText instances
    if (node.target != null) return;

    rule.reportAtNode(node.methodName);
  }
}
