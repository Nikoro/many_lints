import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'bloc_type_checkers.dart';
import 'many_lints_rule.dart';
import 'rule_config.dart';
import 'state_base_classes.dart';

/// How a rule decides which classes hold state.
///
/// The two strategies were once combined in a single rule, which meant a
/// project with no `bloc` dependency still got "Bloc state" diagnostics for
/// every class merely named `...State`. They are separate rules now so each
/// says what it actually checks.
enum StateDetection {
  /// A class used as the state type argument of `Bloc<E, S>` or `Cubit<S>`.
  ///
  /// Inert without the `bloc` package, which is the point: a project not using
  /// Bloc gets nothing.
  blocTypeArgument,

  /// A class whose name matches a configured pattern, defaulting to `State$`.
  ///
  /// Deliberately state-management-agnostic — it covers Riverpod notifier
  /// state, a plain `...State` value object, and anything else a project names
  /// that way.
  namePattern,
}

/// Shared implementation of the two "state classes should be `@immutable`"
/// rules.
///
/// Both walk a compilation unit, decide which classes hold state, widen that
/// set to every subclass and implementor, and report the ones without
/// `@immutable`. Only [detection] differs.
abstract class ImmutableStateRule extends ManyLintsRule {
  ImmutableStateRule({
    required super.name,
    required super.description,
    required this.detection,
  });

  /// Which classes this rule treats as holding state.
  final StateDetection detection;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addCompilationUnit(this, _Visitor(this));
  }
}

/// Reproduces the original `endsWith('State')` heuristic.
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
          // The bare affix itself (`State`) is not a state class, so a match
          // covering the whole name is rejected.
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

    // A subclass of a state class holds the same state, so widen the set.
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

  /// Whether this is a Flutter `State<T>` subclass.
  ///
  /// Every one of them is named `...State` and every one of them is *meant* to
  /// be mutable — holding controllers, `setState` fields and subscriptions is
  /// the entire job of the class. Annotating one `@immutable` would be wrong,
  /// so the name match must not reach them. Without this, the rule reports
  /// every `StatefulWidget` in a codebase.
  bool _isFlutterState(ClassDeclaration declaration) {
    final element = declaration.declaredFragment?.element;
    return element != null && isStateElement(rule, element);
  }

  /// Whether [declaration] already inherits `@immutable` from a supertype.
  ///
  /// Asking for the annotation would be asking for something the class already
  /// has. `StatelessWidget` is the case that matters: Flutter annotates
  /// `Widget` `@immutable`, and widget names ending in `State` are idiomatic —
  /// `EmptyState`, `ErrorState`, `LoadingState` are ordinary component names
  /// describing what is rendered, not a state object. The name-based strategy
  /// has no type information of its own, so without this every such widget is
  /// reported.
  ///
  /// Only supertypes are consulted: an annotation on the class itself is what
  /// [_hasImmutableAnnotation] reports on, and skipping the class here would
  /// hide it from the subclass widening below.
  bool _inheritsImmutable(ClassDeclaration declaration) {
    final element = declaration.declaredFragment?.element;
    if (element == null) return false;

    return element.allSupertypes.any(
      (supertype) => supertype.element.metadata.hasImmutable,
    );
  }

  /// The name of the state type this class supplies to `Bloc` or `Cubit`, or
  /// `null` when it is not a Bloc or Cubit at all.
  String? _blocStateTypeName(ClassDeclaration declaration) {
    final element = declaration.declaredFragment?.element;
    if (element == null) return null;

    // `Bloc<Event, State>` carries the state second, `Cubit<State>` first.
    //
    // Cubit is itself a Bloc, so it has to be tested first: the Bloc branch
    // would otherwise match a Cubit and then look for a second type argument
    // that a `Cubit<State>` does not have.
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
