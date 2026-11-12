import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../state_base_classes.dart';
import '../type_checker.dart';

class AvoidInheritedWidgetInInitstate extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_inherited_widget_in_initstate',
    "Avoid looking up an inherited widget inside 'initState'.",
    correctionMessage:
        "Move this lookup to 'didChangeDependencies', which runs after the "
        'element is mounted and re-runs when the dependency changes.',
  );

  AvoidInheritedWidgetInInitstate()
    : super(
        name: 'avoid_inherited_widget_in_initstate',
        description:
            'Warns when an InheritedWidget is accessed via .of(context) '
            'inside initState, where the lookup is not yet valid.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidInheritedWidgetInInitstate rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'initState') return;

    final enclosingBody = node.parent;
    if (enclosingBody is! BlockClassBody) return;
    final classDecl = enclosingBody.parent;
    if (classDecl is! ClassDeclaration) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null || !isStateElement(rule, element)) return;

    node.body.visitChildren(_InheritedLookupFinder(rule));
  }
}

class _InheritedLookupFinder extends RecursiveAstVisitor<void> {
  final AvoidInheritedWidgetInInitstate rule;

  _InheritedLookupFinder(this.rule);

  static const _inheritedWidgetChecker = TypeChecker.fromName(
    'InheritedWidget',
    packageName: 'flutter',
  );

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (name != 'of' && name != 'maybeOf') {
      super.visitMethodInvocation(node);
      return;
    }

    if (node.target case SimpleIdentifier(element: final target?)) {
      if (target is InterfaceElement &&
          _inheritedWidgetChecker.isSuperOf(target)) {
        rule.reportAtNode(node);
        return;
      }
    }

    super.visitMethodInvocation(node);
  }
}
