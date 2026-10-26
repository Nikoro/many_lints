import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';

/// Warns when an `EdgeInsets` constructor can be replaced with a simpler one.
///
/// Detects cases where:
/// - `EdgeInsets.fromLTRB` can be `EdgeInsets.all`, `.symmetric`, `.only`, or `.zero`
/// - `EdgeInsets.only` can be `EdgeInsets.all`, `.symmetric`, or `.zero`
/// - `EdgeInsets.symmetric` can be `EdgeInsets.all` or `.zero`
/// - `EdgeInsets.all(0)` can be `EdgeInsets.zero`
class PreferCorrectEdgeInsetsConstructor extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_correct_edge_insets_constructor',
    'Use a simpler EdgeInsets constructor.',
    correctionMessage: 'Replace with {0}.',
  );

  PreferCorrectEdgeInsetsConstructor()
    : super(
        name: 'prefer_correct_edge_insets_constructor',
        description:
            'Warns when an EdgeInsets constructor can be replaced with a simpler one.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
    registry.addDotShorthandConstructorInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferCorrectEdgeInsetsConstructor rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final staticType = node.staticType;
    if (staticType == null || !edgeInsetsChecker.isExactlyType(staticType)) {
      return;
    }

    final constructorName = node.constructorName.name?.name;
    _check(node, constructorName, node.argumentList);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final staticType = node.staticType;
    if (staticType == null || !edgeInsetsChecker.isExactlyType(staticType)) {
      return;
    }

    final target = node.target;
    if (target is! SimpleIdentifier) return;

    final constructorName = node.methodName.name;
    _check(node, constructorName, node.argumentList);
  }

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    final staticType = node.staticType;
    if (staticType == null || !edgeInsetsChecker.isExactlyType(staticType)) {
      return;
    }

    _check(node, node.constructorName.name, node.argumentList);
  }

  void _check(
    Expression node,
    String? constructorName,
    ArgumentList argumentList,
  ) {
    switch (constructorName) {
      case 'fromLTRB':
        _checkFromLTRB(node, argumentList);
      case 'only':
        _checkOnly(node, argumentList);
      case 'symmetric':
        _checkSymmetric(node, argumentList);
      case 'all':
        _checkAll(node, argumentList);
    }
  }

  void _checkFromLTRB(Expression node, ArgumentList argumentList) {
    final args = argumentList.arguments;
    if (args.length != 4) return;

    final l = args[0].toSource();
    final t = args[1].toSource();
    final r = args[2].toSource();
    final b = args[3].toSource();

    // All zero → EdgeInsets.zero
    if (_isZeroSource(l) &&
        _isZeroSource(t) &&
        _isZeroSource(r) &&
        _isZeroSource(b)) {
      _report(node, '.zero');
      return;
    }

    // All equal → EdgeInsets.all(v)
    if (l == t && t == r && r == b) {
      _report(node, '.all($l)');
      return;
    }

    // Symmetric → EdgeInsets.symmetric(...)
    if (l == r && t == b) {
      final horizontal = !_isZeroSource(l);
      final vertical = !_isZeroSource(t);
      if (horizontal && vertical) {
        _report(node, '.symmetric(horizontal: $l, vertical: $t)');
      } else if (horizontal) {
        _report(node, '.symmetric(horizontal: $l)');
      } else if (vertical) {
        _report(node, '.symmetric(vertical: $t)');
      }
      return;
    }

    // Check if .only would be simpler (some sides are zero)
    final hasLeft = !_isZeroSource(l);
    final hasTop = !_isZeroSource(t);
    final hasRight = !_isZeroSource(r);
    final hasBottom = !_isZeroSource(b);
    final nonZeroCount = [
      hasLeft,
      hasTop,
      hasRight,
      hasBottom,
    ].where((e) => e).length;

    if (nonZeroCount < 4) {
      final parts = <String>[];
      if (hasLeft) parts.add('left: $l');
      if (hasTop) parts.add('top: $t');
      if (hasRight) parts.add('right: $r');
      if (hasBottom) parts.add('bottom: $b');
      _report(node, '.only(${parts.join(', ')})');
    }
  }

  void _checkOnly(Expression node, ArgumentList argumentList) {
    final args = argumentList.arguments;

    String? left;
    String? top;
    String? right;
    String? bottom;

    for (final arg in args.whereType<NamedArgument>()) {
      switch (arg.name.lexeme) {
        case 'left':
          left = arg.argumentExpression.toSource();
        case 'top':
          top = arg.argumentExpression.toSource();
        case 'right':
          right = arg.argumentExpression.toSource();
        case 'bottom':
          bottom = arg.argumentExpression.toSource();
      }
    }

    final l = left ?? '0';
    final t = top ?? '0';
    final r = right ?? '0';
    final b = bottom ?? '0';

    // All zero → EdgeInsets.zero
    if (_isZeroSource(l) &&
        _isZeroSource(t) &&
        _isZeroSource(r) &&
        _isZeroSource(b)) {
      _report(node, '.zero');
      return;
    }

    // All equal → EdgeInsets.all(v)
    if (l == t && t == r && r == b) {
      _report(node, '.all($l)');
      return;
    }

    // Symmetric → EdgeInsets.symmetric(...)
    if (l == r && t == b) {
      final horizontal = !_isZeroSource(l);
      final vertical = !_isZeroSource(t);
      if (horizontal && vertical) {
        _report(node, '.symmetric(horizontal: $l, vertical: $t)');
      } else if (horizontal) {
        _report(node, '.symmetric(horizontal: $l)');
      } else if (vertical) {
        _report(node, '.symmetric(vertical: $t)');
      }
    }
  }

  void _checkSymmetric(Expression node, ArgumentList argumentList) {
    final args = argumentList.arguments;

    String? horizontal;
    String? vertical;

    for (final arg in args.whereType<NamedArgument>()) {
      switch (arg.name.lexeme) {
        case 'horizontal':
          horizontal = arg.argumentExpression.toSource();
        case 'vertical':
          vertical = arg.argumentExpression.toSource();
      }
    }

    final h = horizontal ?? '0';
    final v = vertical ?? '0';

    // Both zero → EdgeInsets.zero
    if (_isZeroSource(h) && _isZeroSource(v)) {
      _report(node, '.zero');
      return;
    }

    // Both equal → EdgeInsets.all(v)
    if (h == v) {
      _report(node, '.all($h)');
    }
  }

  void _checkAll(Expression node, ArgumentList argumentList) {
    final args = argumentList.arguments;
    if (args.isEmpty) return;

    final value = args.first.toSource();
    if (_isZeroSource(value)) {
      _report(node, '.zero');
    }
  }

  /// Reports [node].
  ///
  /// [argument] should be a dot-shorthand. `EdgeInsets` automatically gets
  /// prepended if the original was not a dot-shorthand.
  void _report(Expression node, String argument) {
    assert(argument.startsWith('.'), 'Argument should be a dot shorthand.');
    final isShorthand = node is DotShorthandConstructorInvocation;
    rule.reportAtNode(
      node,
      arguments: [isShorthand ? argument : 'EdgeInsets$argument'],
    );
  }

  static bool _isZeroSource(String source) {
    return source == '0' || source == '0.0';
  }
}
