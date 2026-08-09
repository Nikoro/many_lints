import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../state_base_classes.dart';
import '../type_checker.dart';

/// Warns when a widget's `build` method instantiates the widget itself
/// unconditionally.
///
/// Building `MyWidget` from inside `MyWidget.build` recurses forever and
/// overflows the stack as soon as the widget is mounted.
///
/// Recursion guarded by a condition is a legitimate way to render trees, so
/// only *unconditional* self-instantiation is reported.
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

  static const _widgetChecker = TypeChecker.fromName(
    'Widget',
    packageName: 'flutter',
  );

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;

    // The type whose construction counts as recursion. For a StatelessWidget
    // that is the class itself; for a State it is the widget it belongs to.
    final InterfaceElement target;
    if (_widgetChecker.isSuperOf(element)) {
      target = element;
    } else if (isStateElement(rule, element)) {
      final widget = _stateWidgetType(node);
      if (widget == null) return;
      target = widget;
    } else {
      return;
    }

    final body = node.body;
    if (body is! BlockClassBody) return;

    for (final member in body.members) {
      if (member is! MethodDeclaration) continue;
      if (member.name.lexeme != 'build') continue;
      member.body.visitChildren(_SelfBuildFinder(rule, target));
    }
  }

  /// Resolves `State<MyWidget>` to the `MyWidget` element.
  InterfaceElement? _stateWidgetType(ClassDeclaration node) {
    final superclass = node.extendsClause?.superclass;
    final typeArguments = superclass?.typeArguments?.arguments;
    if (typeArguments == null || typeArguments.length != 1) return null;

    final type = typeArguments.first.type;
    if (type is! InterfaceType) return null;
    return type.element;
  }
}

/// Finds unconditional construction of [target] inside a build body.
///
/// Skips anything nested in a conditional or a closure: `if (depth > 0)
/// MyWidget(...)` terminates, and a widget built lazily inside a
/// `builder:` callback is only constructed on demand.
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
    // A constructor call without type arguments parses as a MethodInvocation.
    _check(node);
    super.visitMethodInvocation(node);
  }

  void _check(Expression node) {
    final type = node.staticType;
    if (type is! InterfaceType) return;
    if (type.element != target) return;
    rule.reportAtNode(node, arguments: [target.name ?? '']);
  }

  // A conditional makes the recursion terminable — not our business.
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

  // Lazily-built children (builder callbacks) are constructed on demand.
  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
