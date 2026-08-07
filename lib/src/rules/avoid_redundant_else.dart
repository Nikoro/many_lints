import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when an `else` follows a then-branch that always exits.
///
/// If the then-branch ends in `return`, `throw`, `continue` or `break`,
/// control can never reach the `else` from it. Keeping the branch adds a
/// level of indentation for the entire remainder of the method without
/// changing behaviour.
class AvoidRedundantElse extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_redundant_else',
    "This 'else' is redundant because the if branch always exits.",
    correctionMessage:
        "Remove the 'else' and move its body to the enclosing scope.",
  );

  AvoidRedundantElse()
    : super(
        name: 'avoid_redundant_else',
        description:
            'Warns when an else branch follows an if branch that always '
            'returns, throws, continues or breaks.',
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
  final AvoidRedundantElse rule;

  _Visitor(this.rule);

  @override
  void visitIfStatement(IfStatement node) {
    final elseKeyword = node.elseKeyword;
    if (elseKeyword == null) return;

    // `else if` chains read as a single decision; unwinding them into
    // sequential ifs usually hurts rather than helps.
    if (node.elseStatement is IfStatement) return;

    if (!_alwaysExits(node.thenStatement)) return;

    rule.reportAtToken(elseKeyword);
  }

  /// Whether [statement] always transfers control out of the branch.
  bool _alwaysExits(Statement statement) => switch (statement) {
    ReturnStatement() || BreakStatement() || ContinueStatement() => true,

    // `throw` as a statement is an ExpressionStatement wrapping a throw.
    ExpressionStatement(:final expression) => expression is ThrowExpression,

    // A block exits when its last statement does. An empty block does not.
    Block(:final statements) =>
      statements.isNotEmpty && _alwaysExits(statements.last),

    _ => false,
  };
}
