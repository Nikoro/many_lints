import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/ast_node_analysis.dart';

/// Warns when a ConsumerWidget does not use WidgetRef.
class AvoidUnnecessaryConsumerWidgets extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_consumer_widgets',
    'ConsumerWidget does not use WidgetRef. Consider using StatelessWidget instead.',
    correctionMessage: 'Change the base class and remove unused ref parameter.',
  );

  AvoidUnnecessaryConsumerWidgets()
    : super(
        name: 'avoid_unnecessary_consumer_widgets',
        description: 'Warns when ConsumerWidget does not use WidgetRef.',
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
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnnecessaryConsumerWidgets rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration cls) {
    final extendsName = cls.extendsClause?.superclass.name.lexeme;
    if (extendsName != 'ConsumerWidget' &&
        extendsName != 'ConsumerStatefulWidget') {
      return;
    }

    // Find build method
    final body = cls.body;
    if (body is! BlockClassBody) return;

    final buildMethod = body.members
        .whereType<MethodDeclaration>()
        .firstWhereOrNull((m) => m.name.lexeme == 'build');

    if (buildMethod == null) return;

    // Find ref parameter
    final refParam = buildMethod.parameters?.parameters.firstWhereOrNull(
      (p) => p is SimpleFormalParameter && p.name?.lexeme == 'ref',
    );

    if (refParam == null) return;

    // Check if ref is used
    final refUsed = _isIdentifierUsed(buildMethod.body, 'ref');

    if (!refUsed) {
      rule.reportAtToken(cls.namePart.typeName);
    }
  }

  bool _isIdentifierUsed(AstNode? node, String name) {
    if (node == null) return false;

    final visitor = _IdentifierVisitor(name);
    node.visitChildren(visitor);
    return visitor.used;
  }
}

class _IdentifierVisitor extends RecursiveAstVisitor<void> {
  final String name;
  bool used = false;

  _IdentifierVisitor(this.name);

  @override
  void visitSimpleIdentifier(SimpleIdentifier id) {
    if (id.name == name) used = true;
    super.visitSimpleIdentifier(id);
  }
}
