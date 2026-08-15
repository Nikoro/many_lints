import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a `late final` field is assigned more than once on the same
/// path.
///
/// `late final` promises one assignment, and Dart enforces it — but at run
/// time, by throwing `LateInitializationError` on the second write. A second
/// assignment the analyzer can see on one straight-line path is therefore a
/// guaranteed crash, not a possibility.
///
/// Only assignments in the same block are compared, without following
/// branches: two writes in opposite arms of an `if` are exactly how a
/// `late final` is meant to be initialised, so they are left alone.
class AvoidLateFinalReassignment extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_late_final_reassignment',
    "The 'late final' field '{0}' is already assigned on this path.",
    correctionMessage:
        'Assign it once, or drop `final` if it is meant to change.',
  );

  AvoidLateFinalReassignment()
    : super(
        name: 'avoid_late_final_reassignment',
        description:
            'Warns when a `late final` field is assigned twice on one path, '
            'which throws a LateInitializationError at run time.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addBlock(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidLateFinalReassignment rule;

  _Visitor(this.rule);

  @override
  void visitBlock(Block node) {
    // Only statements directly in this block share one path. A nested block
    // gets its own visit, which keeps branches from being compared.
    final assigned = <Element, String>{};

    for (final statement in node.statements) {
      if (statement is! ExpressionStatement) continue;

      final expression = statement.expression;
      if (expression is! AssignmentExpression) continue;
      if (expression.operator.lexeme != '=') continue;

      final target = _lateFinalTarget(expression);
      if (target == null) continue;

      final (element, name) = target;
      if (assigned.containsKey(element)) {
        rule.reportAtNode(expression, arguments: [name]);
      } else {
        assigned[element] = name;
      }
    }
  }

  /// The element and name written by [node], when it targets a `late final`
  /// field, or `null` otherwise.
  (Element, String)? _lateFinalTarget(AssignmentExpression node) {
    final identifier = switch (node.leftHandSide) {
      SimpleIdentifier() && final id => id,
      PropertyAccess(target: ThisExpression(), :final propertyName) =>
        propertyName,
      _ => null,
    };
    if (identifier == null) return null;

    // A write resolves through `writeElement`, and reaches us as a setter; the
    // field it stands for is what carries `isLate` / `isFinal`.
    final element = node.writeElement ?? identifier.element;
    final field = switch (element) {
      SetterElement(:final variable) => variable,
      GetterElement(:final variable) => variable,
      _ => element,
    };

    if (field is! FieldElement) return null;
    if (!field.isLate || !field.isFinal) return null;

    return (field, identifier.name);
  }
}
