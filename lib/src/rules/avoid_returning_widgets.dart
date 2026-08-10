import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';

/// Warns when a function, method, or getter returns a Widget or Widget subclass.
///
/// Extracting widgets to helper methods is a Flutter anti-pattern because
/// Flutter rebuilds the widget tree by calling the function every time,
/// which prevents framework optimizations. Instead, extract widgets into
/// separate widget classes.
///
/// The `build()` override method is exempted since it is the standard
/// way to build widgets.
class AvoidReturningWidgets extends ManyLintsRule {
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
  void registerManyLintsProcessors(
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

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // Exempt build() overrides
    if (node.name.lexeme == 'build') return;

    _checkReturnType(node.returnType, node.name, node.metadata);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _checkReturnType(node.returnType, node.name, node.metadata);
  }

  void _checkReturnType(
    TypeAnnotation? returnType,
    Token nameToken,
    NodeList<Annotation> metadata,
  ) {
    if (returnType == null) return;

    final ignoredNames = rule.config.stringListOption('ignored_names');
    if (ignoredNames.contains(nameToken.lexeme)) return;

    final ignoredAnnotations = rule.config.stringListOption(
      'ignored_annotations',
    );
    if (ignoredAnnotations.isNotEmpty &&
        metadata.any((a) => ignoredAnnotations.contains(a.name.name))) {
      return;
    }

    final type = returnType.type;
    if (type == null) return;

    // `allow_nullable: true` exempts `Widget?` returns, where the null case
    // usually means "render nothing" rather than a widget-building helper.
    if (rule.config.boolOption('allow_nullable', defaultValue: false) &&
        returnType.question != null) {
      return;
    }

    // Handle nullable types: Widget? -> check the underlying type
    final effectiveType = type is InterfaceType ? type : null;
    if (effectiveType == null) return;

    if (widgetChecker.isAssignableFromType(effectiveType)) {
      rule.reportAtToken(nameToken);
    }
  }
}
