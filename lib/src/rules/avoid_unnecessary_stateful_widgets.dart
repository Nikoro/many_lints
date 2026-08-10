import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';
import '../state_base_classes.dart';
import '../state_class_pairing.dart';

/// Warns when a StatefulWidget can be replaced with a StatelessWidget because
/// its State class has no mutable state, lifecycle methods, or setState calls.
class AvoidUnnecessaryStatefulWidgets extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_stateful_widgets',
    'This StatefulWidget has no mutable state. Consider using StatelessWidget instead.',
    correctionMessage: 'Convert to StatelessWidget and move the build method.',
  );

  AvoidUnnecessaryStatefulWidgets()
    : super(
        name: 'avoid_unnecessary_stateful_widgets',
        description:
            'Warns when a StatefulWidget can be replaced with a StatelessWidget.',
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
  final AvoidUnnecessaryStatefulWidgets rule;

  _Visitor(this.rule);

  static const _lifecycleMethods = {
    'initState',
    'dispose',
    'didChangeDependencies',
    'didUpdateWidget',
    'deactivate',
    'activate',
    'reassemble',
  };

  @override
  void visitCompilationUnit(CompilationUnit node) {
    // Collect all State classes and their StatefulWidget pairs
    final statefulWidgets = <ClassDeclaration>[];
    final stateClasses = <ClassDeclaration>[];
    // Mixin declarations in this unit, so a `setState` hidden in one of them
    // can be found; mixins from other files are covered by their elements.
    final localMixins = <String, MixinDeclaration>{};

    for (final declaration in node.declarations) {
      if (declaration is MixinDeclaration) {
        localMixins[declaration.name.lexeme] = declaration;
        continue;
      }
      if (declaration is! ClassDeclaration) continue;

      final element = declaration.declaredFragment?.element;
      if (element == null) continue;

      if (statefulWidgetChecker.isSuperOf(element)) {
        statefulWidgets.add(declaration);
      } else if (isStateElement(rule, element)) {
        stateClasses.add(declaration);
      }
    }

    // For each StatefulWidget, find its companion State class and analyze it
    for (final widget in statefulWidgets) {
      final widgetName = widget.namePart.typeName.lexeme;

      // Find the companion State class
      final stateClass = findStateClassFor(stateClasses, widgetName);
      if (stateClass == null) continue;

      if (_isUnnecessaryState(stateClass) &&
          !_mixesInState(stateClass, localMixins)) {
        rule.reportAtToken(widget.namePart.typeName);
      }
    }
  }

  /// Whether a mixin applied to the State class carries the state itself.
  ///
  /// A mixin `on State<T>` can hold the mutable fields, the lifecycle
  /// overrides and the `setState` calls on behalf of the class that applies
  /// it, which leaves the State body looking empty while the widget is still
  /// genuinely stateful. The mixin usually lives in another file, so this
  /// works off the resolved element rather than the AST.
  static bool _mixesInState(
    ClassDeclaration stateClass,
    Map<String, MixinDeclaration> localMixins,
  ) {
    final mixins = stateClass.withClause?.mixinTypes;
    if (mixins == null) return false;

    for (final mixin in mixins) {
      // A `setState` inside the mixin body means it drives rebuilds; only the
      // declaration carries the method bodies, so this needs the AST.
      final declaration = localMixins[mixin.name.lexeme];
      if (declaration != null) {
        final finder = _SetStateFinder();
        declaration.visitChildren(finder);
        if (finder.found) return true;
      }

      final element = mixin.element;
      if (element is! MixinElement) continue;

      // A non-final, non-static field is mutable state the class inherits.
      // A bare getter surfaces as a field too, so require a real setter:
      // computed values are not state.
      for (final field in element.fields) {
        if (field.isStatic || field.setter == null) continue;
        if (!field.isFinal && !field.isConst) return true;
      }

      // A lifecycle override means the widget has a lifecycle to manage.
      for (final method in element.methods) {
        if (_lifecycleMethods.contains(method.name)) return true;
      }
    }

    return false;
  }

  /// Checks if the State class has no mutable state, lifecycle methods, or
  /// setState calls.
  static bool _isUnnecessaryState(ClassDeclaration stateClass) {
    final body = stateClass.body;
    if (body is! BlockClassBody) return false;

    for (final member in body.members) {
      // Check for mutable instance fields
      if (member is FieldDeclaration) {
        if (member.isStatic) continue;

        final fields = member.fields;
        // const fields are fine
        if (fields.isConst) continue;
        // final fields are fine
        if (fields.isFinal) continue;
        // late final fields are fine
        if (fields.isLate && fields.isFinal) continue;

        // Non-final, non-const, non-static field = mutable state
        return false;
      }

      // Check for lifecycle method overrides (beyond build)
      if (member is MethodDeclaration) {
        final methodName = member.name.lexeme;
        if (_lifecycleMethods.contains(methodName)) {
          return false;
        }
      }
    }

    // Check for setState calls anywhere in the class
    final setStateFinder = _SetStateFinder();
    stateClass.visitChildren(setStateFinder);
    if (setStateFinder.found) return false;

    return true;
  }
}

class _SetStateFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'setState') {
      found = true;
    }
    if (!found) {
      super.visitMethodInvocation(node);
    }
  }
}
