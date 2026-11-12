import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';
import '../state_base_classes.dart';
import '../state_class_pairing.dart';

class UseSliverPrefix extends ManyLintsRule {
  static const LintCode code = LintCode(
    'use_sliver_prefix',
    "Widget returns a sliver but its name does not start with 'Sliver'.",
    correctionMessage: "Add the 'Sliver' prefix to the class name.",
  );

  UseSliverPrefix()
    : super(
        name: 'use_sliver_prefix',
        description:
            'Warns when a widget returns a sliver but lacks the Sliver prefix.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final UseSliverPrefix rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final statefulWidgets = <ClassDeclaration>[];
    final stateClasses = <ClassDeclaration>[];

    for (final declaration in node.declarations) {
      if (declaration is! ClassDeclaration) continue;

      final element = declaration.declaredFragment?.element;
      if (element == null) continue;

      final className = declaration.namePart.typeName.lexeme;

      if (statelessWidgetChecker.isSuperOf(element)) {
        if (!className.startsWith('Sliver') &&
            _buildReturnsSliverWidget(declaration)) {
          rule.reportAtToken(declaration.namePart.typeName);
        }
      } else if (statefulWidgetChecker.isSuperOf(element)) {
        statefulWidgets.add(declaration);
      } else if (isStateElement(rule, element)) {
        stateClasses.add(declaration);
      }
    }

    for (final widget in statefulWidgets) {
      final widgetName = widget.namePart.typeName.lexeme;
      if (widgetName.startsWith('Sliver')) continue;

      final stateClass = findStateClassFor(stateClasses, widgetName);
      if (stateClass == null) continue;

      if (_buildReturnsSliverWidget(stateClass)) {
        rule.reportAtToken(widget.namePart.typeName);
      }
    }
  }

  static bool _buildReturnsSliverWidget(ClassDeclaration node) {
    final body = node.body;
    if (body is! BlockClassBody) return false;

    final buildMethod = body.members
        .whereType<MethodDeclaration>()
        .firstWhereOrNull((m) => m.name.lexeme == 'build');

    if (buildMethod == null) return false;

    final returnExpr = maybeGetSingleReturnExpression(buildMethod.body);
    if (returnExpr == null) return false;

    return _isSliverExpression(returnExpr);
  }

  static bool _isSliverExpression(Expression expression) {
    final type = expression.staticType;
    if (type is! InterfaceType) return false;

    final typeName = type.element.name;
    if (typeName == null) return false;

    if (!typeName.startsWith('Sliver')) return false;

    final libraryUri = type.element.library.identifier;
    return _flutterLibraryPrefixes.any(libraryUri.startsWith);
  }

  static const _flutterLibraryPrefixes = [
    'package:flutter/',
    'package:material_ui/',
  ];
}
