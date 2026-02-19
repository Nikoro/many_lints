import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/ast_node_analysis.dart';
import 'package:many_lints/src/type_checker.dart';

/// Suggests using Center widget instead of Align with center alignment.
class PreferCenterOverAlign extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_center_over_align',
    'Use the Center widget instead of the Align widget with alignment set to Alignment.center',
    correctionMessage: 'Try using Center instead of Align.',
  );

  PreferCenterOverAlign()
    : super(
        name: 'prefer_center_over_align',
        description:
            'Use Center widget instead of Align when alignment is center.',
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
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferCenterOverAlign rule;

  _Visitor(this.rule);

  static const _alignChecker = TypeChecker.fromName(
    'Align',
    packageName: 'flutter',
  );

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!isExpressionExactlyType(node, _alignChecker)) return;

    final arguments = node.argumentList.arguments;
    var hasAlignmentArgument = false;

    for (final argument in arguments.whereType<NamedExpression>()) {
      if (argument.name.label.name == 'alignment') {
        hasAlignmentArgument = true;
        if (_isValueAlignmentCenter(argument)) {
          rule.reportAtNode(node.constructorName);
          return;
        }
      }
    }

    // Align with no alignment parameter defaults to center
    if (!hasAlignmentArgument) {
      rule.reportAtNode(node.constructorName);
    }
  }

  bool _isValueAlignmentCenter(NamedExpression argument) {
    return switch (argument.expression) {
      PrefixedIdentifier(identifier: SimpleIdentifier(name: 'center')) => true,
      InstanceCreationExpression(
        staticType: final type,
        argumentList: ArgumentList(:final arguments),
      )
          when type?.getDisplayString() == 'Alignment' &&
              arguments.length == 2 =>
        _isEveryValueZero(arguments),
      _ => false,
    };
  }

  bool _isEveryValueZero(List<Expression> arguments) => arguments.every(
    (argument) => switch (argument) {
      IntegerLiteral(value: 0) || DoubleLiteral(value: 0) => true,
      _ => false,
    },
  );
}
