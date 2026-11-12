import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../magic_literal_context.dart';
import '../many_lints_rule.dart';

class NoMagicNumber extends ManyLintsRule {
  static const LintCode code = LintCode(
    'no_magic_number',
    'The number {0} is used without a name.',
    correctionMessage: 'Move it to a named constant that says what it means.',
  );

  NoMagicNumber()
    : super(
        name: 'no_magic_number',
        description:
            'Warns when a numeric literal appears without a name to explain '
            'it.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addIntegerLiteral(this, visitor);
    registry.addDoubleLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static final _defaultAllowed = {-1.0, 0.0, 1.0, 2.0};

  static const _defaultIgnoredInvocations = {
    'BorderRadius',
    'Radius',
    'EdgeInsets',
    'EdgeInsetsDirectional',
    'EdgeInsetsGeometry',
    'Gap',
    'SliverGap',
    'SizedBox',
    'Size',
    'Offset',
    'Duration',
    'Rect',
    'Alignment',
  };

  final NoMagicNumber rule;

  _Visitor(this.rule);

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    final value = node.value;
    if (value != null) _check(node, value.toDouble(), node.literal.lexeme);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) =>
      _check(node, node.value, node.literal.lexeme);

  void _check(Literal node, double value, String written) {
    if (rule.config.boolOption('ignore_tests', defaultValue: true) &&
        (rule.relativePath?.startsWith('test/') ?? false)) {
      return;
    }

    final allowed = rule.config.numberSetOption(
      'allowed',
      defaultValue: _defaultAllowed,
    );
    // Edge case: the parser reads `-1` as a negated `1`, so the sign lives on the parent
    final effective = _isNegated(node) ? -value : value;
    if (allowed.contains(effective) || allowed.contains(value)) return;

    if (initialisesADeclaration(node)) return;
    if (isInExemptContext(node)) return;

    final ignoredInvocations = rule.config.nameSetOption(
      'ignored_invocations',
      defaultValue: _defaultIgnoredInvocations,
    );
    if (isArgumentToIgnoredInvocation(node, ignoredInvocations)) return;

    rule.reportAtNode(node, arguments: [written]);
  }

  bool _isNegated(Literal node) {
    final parent = node.parent;

    return parent is PrefixExpression && parent.operator.lexeme == '-';
  }
}
