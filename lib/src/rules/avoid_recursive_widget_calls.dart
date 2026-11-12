import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';
import '../state_base_classes.dart';

class AvoidRecursiveWidgetCalls extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_recursive_widget_calls',
    "The widget '{0}' builds itself unconditionally.",
    correctionMessage:
        'This recurses until the stack overflows. Return a different widget, '
        'or guard the recursion with a condition that terminates.',
  );

  AvoidRecursiveWidgetCalls()
    : super(
        name: 'avoid_recursive_widget_calls',
        description:
            "Warns when a widget's build method instantiates itself "
            'unconditionally, causing infinite recursion.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidRecursiveWidgetCalls rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;

    final builtWidget = _widgetBuiltBy(node, element);
    if (builtWidget == null) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    for (final member in body.members) {
      if (member is! MethodDeclaration) continue;
      if (member.name.lexeme != 'build') continue;
      member.body.visitChildren(_SelfBuildFinder(rule, builtWidget));
    }
  }

  InterfaceElement? _widgetBuiltBy(
    ClassDeclaration node,
    InterfaceElement element,
  ) {
    if (widgetChecker.isSuperOf(element)) return element;
    if (isStateElement(rule, element)) return _stateWidgetType(node);
    return null;
  }

  InterfaceElement? _stateWidgetType(ClassDeclaration node) {
    final superclass = node.extendsClause?.superclass;
    final typeArguments = superclass?.typeArguments?.arguments;
    if (typeArguments == null || typeArguments.length != 1) return null;

    final type = typeArguments.first.type;
    if (type is! InterfaceType) return null;
    return type.element;
  }
}

class _SelfBuildFinder extends RecursiveAstVisitor<void> {
  final AvoidRecursiveWidgetCalls rule;
  final InterfaceElement target;

  _SelfBuildFinder(this.rule, this.target);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _check(node);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Edge case: a constructor call without type arguments can parse as a method call
    _check(node);

    super.visitMethodInvocation(node);
  }

  void _check(Expression node) {
    final type = node.staticType;
    if (type is! InterfaceType) return;
    if (type.element != target) return;
    rule.reportAtNode(node, arguments: [target.name ?? '']);
  }

  @override
  void visitIfStatement(IfStatement node) {}

  @override
  void visitIfElement(IfElement node) {}

  @override
  void visitConditionalExpression(ConditionalExpression node) {}

  @override
  void visitSwitchStatement(SwitchStatement node) {}

  @override
  void visitSwitchExpression(SwitchExpression node) {}

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
