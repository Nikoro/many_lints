import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';

class NeverDiscardBuildContext extends ManyLintsRule {
  static const LintCode code = LintCode(
    'never_discard_build_context',
    "A 'BuildContext' parameter is discarded.",
    correctionMessage:
        "Name the parameter 'context' and use it, so lookups resolve against "
        'the closest element rather than an ancestor.',
  );

  NeverDiscardBuildContext()
    : super(
        name: 'never_discard_build_context',
        description:
            'Warns when a BuildContext parameter is named with a wildcard, '
            'which pushes lookups onto an outer context.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addRegularFormalParameter(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final NeverDiscardBuildContext rule;

  _Visitor(this.rule);

  @override
  void visitRegularFormalParameter(RegularFormalParameter node) {
    final name = node.name;
    if (name == null) return;

    if (!_isWildcard(name.lexeme)) return;

    final element = node.declaredFragment?.element;
    if (element == null) return;
    if (!buildContextChecker.isExactlyType(element.type)) return;

    rule.reportAtToken(name);
  }

  static bool _isWildcard(String lexeme) =>
      lexeme.isNotEmpty && lexeme.split('').every((c) => c == '_');
}
