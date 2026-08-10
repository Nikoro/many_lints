import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';
import '../state_base_classes.dart';
import '../type_checker.dart';

/// Warns when a `late` field's initializer reads `context`.
///
/// A `late` field initializes on first access, and inside a `State` that is
/// usually during `build` — but nothing guarantees it. If the field is first
/// touched from `initState`, the inherited widget lookup runs before the
/// element is mounted and throws.
///
/// Worse, a `late` field initializes exactly once. A value derived from
/// `Theme.of(context)` or `MediaQuery.of(context)` is then frozen at whatever
/// it was on first access, and silently ignores every later change — a theme
/// switch, a rotation, a locale change.
///
/// **Bad:**
/// ```dart
/// class _MyState extends State<MyWidget> {
///   late final theme = Theme.of(context); // frozen, and may run too early
/// }
/// ```
///
/// **Good:**
/// ```dart
/// class _MyState extends State<MyWidget> {
///   @override
///   Widget build(BuildContext context) {
///     final theme = Theme.of(context);
///     ...
///   }
/// }
/// ```
class AvoidLateContext extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_late_context',
    "A 'late' field initializer reads 'context'.",
    correctionMessage:
        "Read the value in 'build' or 'didChangeDependencies' instead, so it "
        'stays current and cannot run before the widget is mounted.',
  );

  AvoidLateContext()
    : super(
        name: 'avoid_late_context',
        description:
            'Warns when a late field initializer uses BuildContext, freezing '
            'the value and risking an unmounted lookup.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addFieldDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidLateContext rule;

  _Visitor(this.rule);

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (!node.fields.isLate) return;
    if (node.isStatic) return;

    // Only inside a `State`: elsewhere `context` is not the ambient widget
    // context this rule is about.
    final classDeclaration = node.parent?.parent;
    if (classDeclaration is! ClassDeclaration) return;

    final element = classDeclaration.declaredFragment?.element;
    if (element == null || !isStateElement(rule, element)) return;

    for (final variable in node.fields.variables) {
      final initializer = variable.initializer;
      if (initializer == null) continue;

      final finder = _ContextFinder(buildContextChecker);
      initializer.accept(finder);

      if (finder.found) rule.reportAtNode(variable);
    }
  }
}

/// Finds a read of `context` — bare, or as `this.context`.
class _ContextFinder extends RecursiveAstVisitor<void> {
  final TypeChecker contextChecker;
  bool found = false;

  _ContextFinder(this.contextChecker);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name != 'context') return;

    // Confirm through the type so an unrelated local named `context` in the
    // initializer does not trigger the rule.
    final type = node.staticType;
    if (type != null && contextChecker.isAssignableFromType(type)) found = true;
  }
}
