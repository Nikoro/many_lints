import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/ast_node_analysis.dart';
import 'package:many_lints/src/type_checker.dart';

/// Warns when a widget's build method returns a sliver widget but the class
/// name does not start with 'Sliver'.
///
/// Consistent naming with a 'Sliver' prefix helps developers quickly identify
/// which widgets are sliver-based and can be used inside CustomScrollView.
class UseSliverPrefix extends AnalysisRule {
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
  void registerNodeProcessors(
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

  static const _statelessWidgetChecker = TypeChecker.fromName(
    'StatelessWidget',
    packageName: 'flutter',
  );

  static const _statefulWidgetChecker = TypeChecker.fromName(
    'StatefulWidget',
    packageName: 'flutter',
  );

  static const _stateChecker = TypeChecker.fromName(
    'State',
    packageName: 'flutter',
  );

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final statefulWidgets = <ClassDeclaration>[];
    final stateClasses = <ClassDeclaration>[];

    for (final declaration in node.declarations) {
      if (declaration is! ClassDeclaration) continue;

      final element = declaration.declaredFragment?.element;
      if (element == null) continue;

      final className = declaration.namePart.typeName.lexeme;

      if (_statelessWidgetChecker.isSuperOf(element)) {
        // StatelessWidget: check build() directly
        if (!className.startsWith('Sliver') &&
            _buildReturnsSliverWidget(declaration)) {
          rule.reportAtToken(declaration.namePart.typeName);
        }
      } else if (_statefulWidgetChecker.isSuperOf(element)) {
        statefulWidgets.add(declaration);
      } else if (_stateChecker.isSuperOf(element)) {
        stateClasses.add(declaration);
      }
    }

    // For StatefulWidgets, find companion State and check its build()
    for (final widget in statefulWidgets) {
      final widgetName = widget.namePart.typeName.lexeme;
      if (widgetName.startsWith('Sliver')) continue;

      final stateClass = _findStateClass(stateClasses, widgetName);
      if (stateClass == null) continue;

      if (_buildReturnsSliverWidget(stateClass)) {
        rule.reportAtToken(widget.namePart.typeName);
      }
    }
  }

  /// Checks if a class has a `build()` method that returns a sliver widget.
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

  /// Finds the State class that corresponds to the given StatefulWidget name.
  static ClassDeclaration? _findStateClass(
    List<ClassDeclaration> stateClasses,
    String widgetName,
  ) {
    for (final stateClass in stateClasses) {
      final superclass = stateClass.extendsClause?.superclass;
      if (superclass == null) continue;

      final typeArgs = superclass.typeArguments?.arguments;
      if (typeArgs != null && typeArgs.length == 1) {
        final typeArg = typeArgs.first;
        if (typeArg is NamedType && typeArg.name.lexeme == widgetName) {
          return stateClass;
        }
      }
    }
    return null;
  }

  /// Checks if the expression's static type is a sliver widget from Flutter.
  static bool _isSliverExpression(Expression expression) {
    final type = expression.staticType;
    if (type is! InterfaceType) return false;

    final typeName = type.element.name;
    if (typeName == null) return false;

    // Check if the type name starts with 'Sliver' and is from Flutter
    if (!typeName.startsWith('Sliver')) return false;

    final libraryUri = type.element.library.identifier;
    return libraryUri.startsWith('package:flutter/');
  }
}
