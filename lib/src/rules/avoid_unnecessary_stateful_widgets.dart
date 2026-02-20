import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when a StatefulWidget can be replaced with a StatelessWidget because
/// its State class has no mutable state, lifecycle methods, or setState calls.
class AvoidUnnecessaryStatefulWidgets extends AnalysisRule {
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
  void registerNodeProcessors(
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

  static const _statefulWidgetChecker = TypeChecker.fromName(
    'StatefulWidget',
    packageName: 'flutter',
  );

  static const _stateChecker = TypeChecker.fromName(
    'State',
    packageName: 'flutter',
  );

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

    for (final declaration in node.declarations) {
      if (declaration is! ClassDeclaration) continue;

      final element = declaration.declaredFragment?.element;
      if (element == null) continue;

      if (_statefulWidgetChecker.isSuperOf(element)) {
        statefulWidgets.add(declaration);
      } else if (_stateChecker.isSuperOf(element)) {
        stateClasses.add(declaration);
      }
    }

    // For each StatefulWidget, find its companion State class and analyze it
    for (final widget in statefulWidgets) {
      final widgetName = widget.namePart.typeName.lexeme;

      // Find the companion State class
      final stateClass = _findStateClass(stateClasses, widgetName);
      if (stateClass == null) continue;

      if (_isUnnecessaryState(stateClass)) {
        rule.reportAtToken(widget.namePart.typeName);
      }
    }
  }

  /// Finds the State class that corresponds to the given StatefulWidget name.
  /// Looks for `State<WidgetName>` in the extends clause.
  static ClassDeclaration? _findStateClass(
    List<ClassDeclaration> stateClasses,
    String widgetName,
  ) {
    for (final stateClass in stateClasses) {
      final superclass = stateClass.extendsClause?.superclass;
      if (superclass == null) continue;

      // Check if extends State<WidgetName>
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
