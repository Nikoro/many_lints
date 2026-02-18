import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a pattern variable declaration destructures only a single field.
///
/// Single-field destructuring adds unnecessary complexity compared to direct
/// property access. Use regular variable declarations instead:
///
/// ```dart
/// // Bad
/// final SomeClass(:value) = input;
/// final (:length) = [1, 2, 3];
///
/// // Good
/// final value = input.value;
/// final length = [1, 2, 3].length;
/// ```
class AvoidSingleFieldDestructuring extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_single_field_destructuring',
    'Avoid single-field destructuring. Use direct property access instead.',
    correctionMessage:
        'Replace destructuring with direct property access on the expression.',
  );

  AvoidSingleFieldDestructuring()
    : super(
        name: 'avoid_single_field_destructuring',
        description:
            'Warns when a pattern variable declaration destructures only a '
            'single field.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addPatternVariableDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidSingleFieldDestructuring rule;

  _Visitor(this.rule);

  @override
  void visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    final pattern = node.pattern;

    if (pattern is ObjectPattern && pattern.fields.length == 1) {
      rule.reportAtNode(node);
      return;
    }

    if (pattern is RecordPattern && pattern.fields.length == 1) {
      rule.reportAtNode(node);
      return;
    }
  }
}
