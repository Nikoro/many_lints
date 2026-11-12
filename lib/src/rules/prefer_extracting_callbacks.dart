import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';

class PreferExtractingCallbacks extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_extracting_callbacks',
    'This inline callback holds {0} statements.',
    correctionMessage:
        'Extract it to a method so the widget tree stays readable.',
  );

  PreferExtractingCallbacks()
    : super(
        name: 'prefer_extracting_callbacks',
        description:
            "Warns when a widget's callback argument holds a long inline "
            'closure.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferExtractingCallbacks rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final element = node.constructorName.type.element;
    if (element == null || !widgetChecker.isSuperOf(element)) return;

    _checkArguments(node.argumentList);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!rule.config.boolOption('report_functions', defaultValue: false)) {
      return;
    }

    _checkArguments(node.argumentList);
  }

  void _checkArguments(ArgumentList arguments) {
    final maxStatements = rule.config.intOption(
      'max_statements',
      defaultValue: 3,
    );
    final ignored = rule.config.nameSetOption(
      'ignored_parameters',
      defaultValue: const {'builder', 'itemBuilder', 'separatorBuilder'},
    );

    for (final argument in arguments.arguments) {
      if (argument is! NamedArgument) continue;

      final name = argument.name.lexeme;
      // Edge case: extracting a `builder` would trip `avoid_returning_widgets` instead
      if (ignored.contains(name)) continue;

      final closure = argument.argumentExpression;
      if (closure is! FunctionExpression) continue;

      final body = closure.body;
      if (body is! BlockFunctionBody) continue;

      final statements = body.block.statements.length;
      if (statements <= maxStatements) continue;

      rule.reportAtNode(closure, arguments: ['$statements']);
    }
  }
}
