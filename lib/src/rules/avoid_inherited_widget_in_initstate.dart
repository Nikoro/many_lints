import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when an inherited widget is looked up inside `initState`.
///
/// `dependOnInheritedWidgetOfExactType` — which powers `Theme.of(context)`,
/// `MediaQuery.of(context)` and friends — is not usable from `initState`.
/// The element is not yet fully mounted in the tree, so the lookup either
/// throws or registers a dependency that never produces updates.
///
/// Move the lookup to `didChangeDependencies`, which runs once after
/// `initState` and again whenever a dependency changes.
class AvoidInheritedWidgetInInitstate extends AnalysisRule {
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
  void registerNodeProcessors(
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

  static const _stateChecker = TypeChecker.fromName(
    'State',
    packageName: 'flutter',
  );

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'initState') return;

    final enclosingBody = node.parent;
    if (enclosingBody is! BlockClassBody) return;
    final classDecl = enclosingBody.parent;
    if (classDecl is! ClassDeclaration) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null || !_stateChecker.isSuperOf(element)) return;

    node.body.visitChildren(_InheritedLookupFinder(rule));
  }
}

/// Finds `SomeInheritedWidget.of(context)` calls.
///
/// Descends into closures deliberately: a lookup inside a closure that is
/// invoked synchronously from `initState` fails the same way. Closures that
/// merely *escape* `initState` (e.g. passed to `addPostFrameCallback`) are
/// the one shape this over-reports, which is why the check is narrow in
/// every other dimension.
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

    // The target must be a plain type reference: `Theme.of(...)`.
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
