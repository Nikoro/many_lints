import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/type_checker.dart';

/// Warns when a function, method, or getter returns a Widget or Widget subclass.
///
/// Extracting widgets to helper methods is a Flutter anti-pattern because
/// Flutter rebuilds the widget tree by calling the function every time,
/// which prevents framework optimizations. Instead, extract widgets into
/// separate widget classes.
///
/// The `build()` override method is exempted since it is the standard
/// way to build widgets.
class AvoidReturningWidgets extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_returning_widgets',
    'Avoid returning widgets from functions, methods, or getters.',
    correctionMessage: 'Extract the widget into a separate widget class.',
  );

  AvoidReturningWidgets()
    : super(
        name: 'avoid_returning_widgets',
        description:
            'Warns when a function, method, or getter returns a Widget '
            'or Widget subclass instead of using a dedicated widget class.',
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
    registry.addFunctionDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidReturningWidgets rule;

  _Visitor(this.rule);

  static const _widgetChecker = TypeChecker.fromName(
    'Widget',
    packageName: 'flutter',
  );

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // Exempt build() overrides
    if (node.name.lexeme == 'build') return;

    _checkReturnType(node.returnType, node.name);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _checkReturnType(node.returnType, node.name);
  }

  void _checkReturnType(TypeAnnotation? returnType, Token nameToken) {
    if (returnType == null) return;

    final type = returnType.type;
    if (type == null) return;

    // Handle nullable types: Widget? -> check the underlying type
    final effectiveType = type is InterfaceType ? type : null;
    if (effectiveType == null) return;

    if (_widgetChecker.isAssignableFromType(effectiveType)) {
      rule.reportAtToken(nameToken);
    }
  }
}
