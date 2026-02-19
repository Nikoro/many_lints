import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when a Bloc/Cubit state class is not annotated with `@immutable`.
///
/// Immutable state objects ensure that `emit` always receives a newly created
/// object, preventing stale state bugs where the state reference hasn't changed.
///
/// Detection uses two strategies:
/// 1. Classes whose name ends with `State` that extend/implement other state
///    classes in the Bloc pattern.
/// 2. Classes used as the state type parameter of a `Bloc` or `Cubit`.
class PreferImmutableBlocState extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_immutable_bloc_state',
    'Bloc state classes should be annotated with @immutable.',
    correctionMessage: "Add '@immutable' annotation to this class.",
  );

  PreferImmutableBlocState()
    : super(
        name: 'prefer_immutable_bloc_state',
        description:
            'Warns when a Bloc/Cubit state class lacks the @immutable annotation.',
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
  final PreferImmutableBlocState rule;

  _Visitor(this.rule);

  static const _blocChecker = TypeChecker.fromName('Bloc', packageName: 'bloc');

  static const _cubitChecker = TypeChecker.fromName(
    'Cubit',
    packageName: 'bloc',
  );

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final stateClassNames = <String>{};

    // Strategy 1: Find classes used as state type parameter of Bloc/Cubit
    for (final declaration in node.declarations) {
      if (declaration is! ClassDeclaration) continue;

      final element = declaration.declaredFragment?.element;
      if (element == null) continue;

      if (_blocChecker.isSuperOf(element) && !_blocChecker.isExactly(element)) {
        // Bloc<Event, State> — state is the second type arg
        final typeArgs =
            declaration.extendsClause?.superclass.typeArguments?.arguments;
        if (typeArgs != null && typeArgs.length == 2) {
          final stateType = typeArgs[1];
          if (stateType is NamedType) {
            stateClassNames.add(stateType.name.lexeme);
          }
        }
      } else if (_cubitChecker.isSuperOf(element) &&
          !_cubitChecker.isExactly(element)) {
        // Cubit<State> — state is the first type arg
        final typeArgs =
            declaration.extendsClause?.superclass.typeArguments?.arguments;
        if (typeArgs != null && typeArgs.length == 1) {
          final stateType = typeArgs.first;
          if (stateType is NamedType) {
            stateClassNames.add(stateType.name.lexeme);
          }
        }
      }
    }

    // Strategy 2: Find classes whose name ends with 'State' and that
    // participate in a sealed/extends hierarchy with known state classes
    for (final declaration in node.declarations) {
      if (declaration is! ClassDeclaration) continue;

      final className = declaration.namePart.typeName.lexeme;

      // Check if name ends with 'State'
      if (className.endsWith('State') && className.length > 5) {
        stateClassNames.add(className);
      }
    }

    // Also add subclasses of known state classes using a single-pass BFS.
    // Build a parent→children adjacency map, then propagate from known roots.
    final childrenOf = <String, List<String>>{};
    for (final declaration in node.declarations) {
      if (declaration is! ClassDeclaration) continue;

      final className = declaration.namePart.typeName.lexeme;

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

    // BFS from known state class names
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

    // Now check each state class for @immutable annotation
    for (final declaration in node.declarations) {
      if (declaration is! ClassDeclaration) continue;

      final className = declaration.namePart.typeName.lexeme;
      if (!stateClassNames.contains(className)) continue;

      if (!_hasImmutableAnnotation(declaration)) {
        rule.reportAtToken(declaration.namePart.typeName);
      }
    }
  }

  static bool _hasImmutableAnnotation(ClassDeclaration node) {
    for (final annotation in node.metadata) {
      if (annotation.name.name == 'immutable') return true;
    }
    return false;
  }
}
