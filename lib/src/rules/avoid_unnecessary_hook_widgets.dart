import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/ast_node_analysis.dart';
import 'package:many_lints/src/hook_detection.dart';
import 'package:many_lints/src/type_checker.dart';

/// Warns when a HookWidget does not use any hooks in the build method.
class AvoidUnnecessaryHookWidgets extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_hook_widgets',
    'This HookWidget does not use hooks.',
    correctionMessage: 'Convert it to a StatelessWidget',
  );

  AvoidUnnecessaryHookWidgets()
    : super(
        name: 'avoid_unnecessary_hook_widgets',
        description: 'Warns when HookWidget does not use hooks.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnnecessaryHookWidgets rule;

  _Visitor(this.rule);

  static const _hookWidgetChecker = TypeChecker.any([
    TypeChecker.fromName('HookWidget', packageName: 'flutter_hooks'),
    TypeChecker.fromName('HookConsumerWidget', packageName: 'hooks_riverpod'),
  ]);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final superclass = node.extendsClause?.superclass;
    final superclassElement = superclass?.element;
    if (superclass == null || superclassElement == null) return;

    if (!_hookWidgetChecker.isExactly(superclassElement)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    final buildMethod = body.members
        .whereType<MethodDeclaration>()
        .firstWhereOrNull((member) => member.name.lexeme == 'build');
    if (buildMethod == null) return;

    final hookExpressions = getAllInnerHookExpressions(buildMethod.body);
    if (hookExpressions.isEmpty) {
      rule.reportAtNode(superclass);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final body = maybeHookBuilderBody(node);
    if (body == null) return;

    final hookExpressions = getAllInnerHookExpressions(body);
    if (hookExpressions.isEmpty) {
      rule.reportAtNode(node.constructorName);
    }
  }
}
