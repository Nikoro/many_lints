import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Warns when an if-else chain compares one enum value against several
/// constants.
///
/// A `switch` over an enum is checked for exhaustiveness: add a constant
/// and the compiler points at every switch that must handle it. An if-else
/// chain gets no such check, so a new constant silently falls through to
/// the final `else` — or to nothing at all.
class PreferSwitchWithEnums extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_switch_with_enums',
    "This if-else chain compares '{0}' against several enum constants.",
    correctionMessage:
        'Use a switch so the compiler checks that every constant is '
        'handled.',
  );

  /// Minimum number of chained comparisons before a switch is worth it.
  static const _threshold = 3;

  PreferSwitchWithEnums()
    : super(
        name: 'prefer_switch_with_enums',
        description:
            'Warns when an if-else chain compares an enum value against '
            'several constants instead of using a switch.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addIfStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferSwitchWithEnums rule;

  _Visitor(this.rule);

  @override
  void visitIfStatement(IfStatement node) {
    // Only look at the head of a chain, so one chain reports once.
    if (node.parent is IfStatement) return;

    String? subject;
    var comparisons = 0;

    for (IfStatement? current = node; current != null;) {
      final compared = _comparedEnumSubject(current.expression);
      if (compared == null) return;

      subject ??= compared;
      // Every branch must test the same value for a switch to replace it.
      if (compared != subject) return;

      comparisons++;

      final elseStatement = current.elseStatement;
      current = elseStatement is IfStatement ? elseStatement : null;
    }

    if (comparisons < PreferSwitchWithEnums._threshold) return;

    rule.reportAtNode(node.expression, arguments: [subject!]);
  }

  /// Returns the source of the compared value when [expression] is
  /// `subject == EnumType.constant`, or `null` otherwise.
  String? _comparedEnumSubject(Expression expression) {
    if (expression is! BinaryExpression) return null;
    if (expression.operator.lexeme != '==') return null;

    final left = expression.leftOperand;
    final right = expression.rightOperand;

    if (_isEnumConstant(right) && _isNonNullableEnum(left)) {
      return left.toSource();
    }
    if (_isEnumConstant(left) && _isNonNullableEnum(right)) {
      return right.toSource();
    }
    return null;
  }

  bool _isEnumConstant(Expression expression) {
    final element = switch (expression) {
      PrefixedIdentifier(:final identifier) => identifier.element,
      PropertyAccess(:final propertyName) => propertyName.element,
      _ => null,
    };

    if (element is! GetterElement) return false;
    final variable = element.variable;
    return variable is FieldElement && variable.enclosingElement is EnumElement;
  }

  bool _isNonNullableEnum(Expression expression) {
    final type = expression.staticType;
    if (type is! InterfaceType) return false;
    if (type.nullabilitySuffix != NullabilitySuffix.none) return false;
    return type.element is EnumElement;
  }
}
