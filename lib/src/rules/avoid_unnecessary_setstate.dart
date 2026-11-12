import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../state_base_classes.dart';

class AvoidUnnecessarySetstate extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_setstate',
    "Unnecessary call to 'setState' inside '{0}'.",
    correctionMessage:
        'Mutate the state directly without calling setState in this method.',
  );

  AvoidUnnecessarySetstate()
    : super(
        name: 'avoid_unnecessary_setstate',
        description:
            'Warns when setState is called in initState, didUpdateWidget, '
            'or build where it is unnecessary.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnnecessarySetstate rule;

  _Visitor(this.rule);

  static const _lifecycleMethods = {'initState', 'didUpdateWidget', 'build'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'setState') return;

    final (:method, :classDecl) = _findLifecycleMethodAndClass(node);
    if (method == null || classDecl == null) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null || !isStateElement(rule, element)) return;

    final methodName = method.name.lexeme;

    if (methodName == 'build' && _isInsideEventHandlerCallback(node)) return;

    rule.reportAtNode(node, arguments: [methodName]);
  }

  static ({MethodDeclaration? method, ClassDeclaration? classDecl})
  _findLifecycleMethodAndClass(AstNode node) {
    MethodDeclaration? method;
    AstNode? current = node.parent;
    while (current != null) {
      if (method == null) {
        if (current is FunctionExpression || current is FunctionDeclaration) {
          return (method: null, classDecl: null);
        }
        if (current is MethodDeclaration) {
          final name = current.name.lexeme;
          if (!_lifecycleMethods.contains(name)) {
            return (method: null, classDecl: null);
          }
          method = current;
        }
      } else if (current is ClassDeclaration) {
        return (method: method, classDecl: current);
      }
      current = current.parent;
    }
    return (method: null, classDecl: null);
  }

  static bool _isInsideEventHandlerCallback(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is MethodDeclaration) return false;

      if (current is FunctionExpression) {
        final parent = current.parent;
        if (parent is NamedArgument) return true;
      }

      current = current.parent;
    }
    return false;
  }
}
