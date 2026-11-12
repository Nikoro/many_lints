import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidLongFunctions extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_long_functions',
    'This function body is {0} lines long, over the limit of {1}.',
    correctionMessage:
        'Split out the part that has its own name, or raise max_lines.',
  );

  AvoidLongFunctions()
    : super(
        name: 'avoid_long_functions',
        description:
            'Warns when a function body exceeds the configured line budget.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addConstructorDeclaration(this, visitor);
  }
}

const _defaultMaxLines = 50;

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidLongFunctions rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) =>
      _check(node.functionExpression.body, node.name);

  @override
  void visitMethodDeclaration(MethodDeclaration node) =>
      _check(node.body, node.name);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    // Edge case: an unnamed constructor has no name token to point at
    _check(node.body, node.name, fallback: node);
  }

  void _check(FunctionBody body, Token? name, {AstNode? fallback}) {
    if (body is! BlockFunctionBody) return;

    final maxLines = rule.config.intOption(
      'max_lines',
      defaultValue: _defaultMaxLines,
    );

    final unit = body.thisOrAncestorOfType<CompilationUnit>();
    if (unit == null) return;

    final lineInfo = unit.lineInfo;
    final first = lineInfo.getLocation(body.offset).lineNumber;
    final last = lineInfo.getLocation(body.end).lineNumber;

    final linesBetweenBraces = last - first - 1;
    if (linesBetweenBraces <= maxLines) return;

    final arguments = ['$linesBetweenBraces', '$maxLines'];
    if (name != null) {
      rule.reportAtToken(name, arguments: arguments);
    } else if (fallback != null) {
      rule.reportAtNode(fallback, arguments: arguments);
    }
  }
}
