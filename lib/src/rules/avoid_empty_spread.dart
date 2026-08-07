import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a spread element spreads an empty literal.
///
/// `...[]`, `...{}` and their null-aware forms contribute nothing to the
/// surrounding collection. They are usually left behind after a refactor,
/// or written as a placeholder that was never filled in.
class AvoidEmptySpread extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_empty_spread',
    'Spreading an empty collection has no effect.',
    correctionMessage: 'Remove this spread element.',
  );

  AvoidEmptySpread()
    : super(
        name: 'avoid_empty_spread',
        description:
            'Warns when a spread element spreads an empty collection '
            'literal, which contributes nothing.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addSpreadElement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidEmptySpread rule;

  _Visitor(this.rule);

  @override
  void visitSpreadElement(SpreadElement node) {
    if (_isEmptyLiteral(node.expression)) {
      rule.reportAtNode(node);
    }
  }

  bool _isEmptyLiteral(Expression expression) => switch (expression) {
    ListLiteral(:final elements) => elements.isEmpty,
    SetOrMapLiteral(:final elements) => elements.isEmpty,
    _ => false,
  };
}
