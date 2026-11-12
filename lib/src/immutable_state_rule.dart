import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'bloc_type_checkers.dart';
import 'many_lints_rule.dart';
import 'rule_config.dart';
import 'state_base_classes.dart';

enum StateDetection { blocTypeArgument, namePattern }

abstract class ImmutableStateRule extends ManyLintsRule {
  ImmutableStateRule({
    required super.name,
    required super.description,
    required this.detection,
  });

  final StateDetection detection;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addCompilationUnit(this, _Visitor(this));
  }
}

final _defaultNamePattern = RegExp(r'State$');

class _Visitor extends SimpleAstVisitor<void> {
  final ImmutableStateRule rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final stateClassNames = <String>{};
    final childrenOf = <String, List<String>>{};

    final namePattern = rule.config.patternOption(
      'name_pattern',
      defaultValue: _defaultNamePattern,
    )!;

    for (final declaration in node.declarations) {
      if (declaration is! ClassDeclaration) continue;

      final className = declaration.namePart.typeName.lexeme;

      switch (rule.detection) {
        case StateDetection.blocTypeArgument:
          if (_blocStateTypeName(declaration) case final stateType?) {
            stateClassNames.add(stateType);
          }

        case StateDetection.namePattern:
          if (namePattern.hasMatch(className) &&
              !namePattern.matchesWholeValue(className) &&
              !_isFlutterState(declaration) &&
              !_inheritsImmutable(declaration)) {
            stateClassNames.add(className);
          }
      }

      final superclass = declaration.extendsClause?.superclass;
      if (superclass != null) {
        (childrenOf[superclass.name.lexeme] ??= []).add(className);
      }

      final implementsClause = declaration.implementsClause;
      if (implementsClause != null) {
        for (final implemented in implementsClause.interfaces) {
          (childrenOf[implemented.name.lexeme] ??= []).add(className);
        }
      }
    }

    final queue = [...stateClassNames];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      final children = childrenOf[current];
      if (children == null) continue;
      for (final child in children) {
        if (stateClassNames.add(child)) {
          queue.add(child);
        }
      }
    }

    for (final declaration in node.declarations) {
      if (declaration is! ClassDeclaration) continue;

      final className = declaration.namePart.typeName.lexeme;
      if (!stateClassNames.contains(className)) continue;

      if (!_hasImmutableAnnotation(declaration)) {
        rule.reportAtToken(declaration.namePart.typeName);
      }
    }
  }

  bool _isFlutterState(ClassDeclaration declaration) {
    final element = declaration.declaredFragment?.element;
    return element != null && isStateElement(rule, element);
  }

  bool _inheritsImmutable(ClassDeclaration declaration) {
    final element = declaration.declaredFragment?.element;
    if (element == null) return false;

    return element.allSupertypes.any(
      (supertype) => supertype.element.metadata.hasImmutable,
    );
  }

  String? _blocStateTypeName(ClassDeclaration declaration) {
    final element = declaration.declaredFragment?.element;
    if (element == null) return null;

    // Edge case: Cubit is a Bloc, so it is tested first or the second type argument is missing
    final stateArgumentIndex = switch (element) {
      _
          when cubitChecker.isSuperOf(element) &&
              !cubitChecker.isExactly(element) =>
        0,
      _
          when blocChecker.isSuperOf(element) &&
              !blocChecker.isExactly(element) =>
        1,
      _ => null,
    };
    if (stateArgumentIndex == null) return null;

    final typeArguments =
        declaration.extendsClause?.superclass.typeArguments?.arguments;
    if (typeArguments == null) return null;
    if (typeArguments.length <= stateArgumentIndex) return null;

    final stateType = typeArguments[stateArgumentIndex];
    return stateType is NamedType ? stateType.name.lexeme : null;
  }

  static bool _hasImmutableAnnotation(ClassDeclaration node) {
    for (final annotation in node.metadata) {
      if (annotation.name.name == 'immutable') return true;
    }
    return false;
  }
}
