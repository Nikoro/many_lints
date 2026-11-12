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
    final statefulWidgets = <ClassDeclaration>[];
    final stateClasses = <ClassDeclaration>[];
    final mixinsInUnit = <String, MixinDeclaration>{};

    for (final declaration in node.declarations) {
      if (declaration is MixinDeclaration) {
        mixinsInUnit[declaration.name.lexeme] = declaration;
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

    for (final widget in statefulWidgets) {
      final widgetName = widget.namePart.typeName.lexeme;

      final stateClass = findStateClassFor(stateClasses, widgetName);
      if (stateClass == null) continue;

      if (_isUnnecessaryState(stateClass) &&
          !_mixesInState(stateClass, mixinsInUnit)) {
        rule.reportAtToken(widget.namePart.typeName);
      }
    }
  }

  static bool _mixesInState(
    ClassDeclaration stateClass,
    Map<String, MixinDeclaration> mixinsInUnit,
  ) {
    final mixins = stateClass.withClause?.mixinTypes;
    if (mixins == null) return false;

    for (final mixin in mixins) {
      // Edge case: elements carry no method bodies, so a setState is only visible in this unit's AST
      final declaration = mixinsInUnit[mixin.name.lexeme];
      if (declaration != null) {
        final finder = _SetStateFinder();
        declaration.visitChildren(finder);
        if (finder.found) return true;
      }

      final element = mixin.element;
      if (element is! MixinElement) continue;

      // Edge case: a bare getter surfaces as a field without a setter; computed values are not state
      for (final field in element.fields) {
        if (field.isStatic || field.setter == null) continue;
        if (!field.isFinal && !field.isConst) return true;
      }

      for (final method in element.methods) {
        if (_lifecycleMethods.contains(method.name)) return true;
      }
    }

    return false;
  }

  static bool _isUnnecessaryState(ClassDeclaration stateClass) {
    final body = stateClass.body;
    if (body is! BlockClassBody) return false;

    for (final member in body.members) {
      if (member is FieldDeclaration) {
        if (member.isStatic) continue;

        final fields = member.fields;
        if (fields.isConst || fields.isFinal) continue;

        return false;
      }

      if (member is MethodDeclaration) {
        final methodName = member.name.lexeme;
        if (_lifecycleMethods.contains(methodName)) {
          return false;
        }
      }
    }

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
