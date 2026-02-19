import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/ast_node_analysis.dart';
import 'package:many_lints/src/type_checker.dart';

/// Warns when a `SizedBox` is created with identical `height` and `width`
/// values. Use `SizedBox.square(dimension: ...)` instead for cleaner code.
class PreferSizedBoxSquare extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_sized_box_square',
    'Use SizedBox.square instead of SizedBox with equal width and height.',
    correctionMessage: 'Try using SizedBox.square(dimension: ...) instead.',
  );

  PreferSizedBoxSquare()
    : super(
        name: 'prefer_sized_box_square',
        description:
            'Prefer SizedBox.square when width and height are identical.',
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
  final PreferSizedBoxSquare rule;

  _Visitor(this.rule);

  static const _sizedBoxChecker = TypeChecker.fromName(
    'SizedBox',
    packageName: 'flutter',
  );

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Skip named constructors like SizedBox.square, SizedBox.shrink, etc.
    if (node.constructorName.name != null) return;
    _check(node.staticType, node.argumentList, node.constructorName);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final type = node.staticType;
    if (type == null || !_sizedBoxChecker.isExactlyType(type)) return;
    // MethodInvocation for SizedBox() without type args — skip named
    // constructors (target would be 'SizedBox', methodName would be 'square')
    if (node.target != null) return;
    _check(type, node.argumentList, node.methodName);
  }

  void _check(
    DartType? staticType,
    ArgumentList argumentList,
    AstNode reportNode,
  ) {
    if (staticType == null) return;
    if (!_sizedBoxChecker.isExactlyType(staticType)) return;

    final args = argumentList.arguments.whereType<NamedExpression>();

    final widthArg = args.firstWhereOrNull((a) => a.name.label.name == 'width');
    final heightArg = args.firstWhereOrNull(
      (a) => a.name.label.name == 'height',
    );

    // Both width and height must be present
    if (widthArg == null || heightArg == null) return;

    // Check if both values are identical by comparing their source text
    final widthSource = widthArg.expression.toSource();
    final heightSource = heightArg.expression.toSource();

    if (widthSource == heightSource) {
      rule.reportAtNode(reportNode);
    }
  }
}
