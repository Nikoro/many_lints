import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/type_checker.dart';

/// Warns when an `EdgeInsets` constructor can be replaced with a simpler one.
///
/// Detects cases where:
/// - `EdgeInsets.fromLTRB` can be `EdgeInsets.all`, `.symmetric`, `.only`, or `.zero`
/// - `EdgeInsets.only` can be `EdgeInsets.all`, `.symmetric`, or `.zero`
/// - `EdgeInsets.symmetric` can be `EdgeInsets.all` or `.zero`
/// - `EdgeInsets.all(0)` can be `EdgeInsets.zero`
class PreferCorrectEdgeInsetsConstructor extends AnalysisRule {
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
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferCorrectEdgeInsetsConstructor rule;

  _Visitor(this.rule);

  static const _edgeInsetsChecker = TypeChecker.fromName(
    'EdgeInsets',
    packageName: 'flutter',
  );

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final staticType = node.staticType;
    if (staticType == null || !_edgeInsetsChecker.isExactlyType(staticType)) {
      return;
    }

    final constructorName = node.constructorName.name?.name;
    _check(node, constructorName, node.argumentList);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final staticType = node.staticType;
    if (staticType == null || !_edgeInsetsChecker.isExactlyType(staticType)) {
      return;
    }

    final target = node.target;
    if (target is! SimpleIdentifier) return;

    final constructorName = node.methodName.name;
    _check(node, constructorName, node.argumentList);
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
      rule.reportAtNode(node, arguments: ['EdgeInsets.zero']);
      return;
    }

    // All equal → EdgeInsets.all(v)
    if (l == t && t == r && r == b) {
      rule.reportAtNode(node, arguments: ['EdgeInsets.all($l)']);
      return;
    }

    // Symmetric → EdgeInsets.symmetric(...)
    if (l == r && t == b) {
      final horizontal = !_isZeroSource(l);
      final vertical = !_isZeroSource(t);
      if (horizontal && vertical) {
        rule.reportAtNode(
          node,
          arguments: ['EdgeInsets.symmetric(horizontal: $l, vertical: $t)'],
        );
      } else if (horizontal) {
        rule.reportAtNode(
          node,
          arguments: ['EdgeInsets.symmetric(horizontal: $l)'],
        );
      } else if (vertical) {
        rule.reportAtNode(
          node,
          arguments: ['EdgeInsets.symmetric(vertical: $t)'],
        );
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
      rule.reportAtNode(
        node,
        arguments: ['EdgeInsets.only(${parts.join(', ')})'],
      );
    }
  }

  void _checkOnly(Expression node, ArgumentList argumentList) {
    final args = argumentList.arguments;

    String? left;
    String? top;
    String? right;
    String? bottom;

    for (final arg in args.whereType<NamedExpression>()) {
      switch (arg.name.label.name) {
        case 'left':
          left = arg.expression.toSource();
        case 'top':
          top = arg.expression.toSource();
        case 'right':
          right = arg.expression.toSource();
        case 'bottom':
          bottom = arg.expression.toSource();
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
      rule.reportAtNode(node, arguments: ['EdgeInsets.zero']);
      return;
    }

    // All equal → EdgeInsets.all(v)
    if (l == t && t == r && r == b) {
      rule.reportAtNode(node, arguments: ['EdgeInsets.all($l)']);
      return;
    }

    // Symmetric → EdgeInsets.symmetric(...)
    if (l == r && t == b) {
      final horizontal = !_isZeroSource(l);
      final vertical = !_isZeroSource(t);
      if (horizontal && vertical) {
        rule.reportAtNode(
          node,
          arguments: ['EdgeInsets.symmetric(horizontal: $l, vertical: $t)'],
        );
      } else if (horizontal) {
        rule.reportAtNode(
          node,
          arguments: ['EdgeInsets.symmetric(horizontal: $l)'],
        );
      } else if (vertical) {
        rule.reportAtNode(
          node,
          arguments: ['EdgeInsets.symmetric(vertical: $t)'],
        );
      }
    }
  }

  void _checkSymmetric(Expression node, ArgumentList argumentList) {
    final args = argumentList.arguments;

    String? horizontal;
    String? vertical;

    for (final arg in args.whereType<NamedExpression>()) {
      switch (arg.name.label.name) {
        case 'horizontal':
          horizontal = arg.expression.toSource();
        case 'vertical':
          vertical = arg.expression.toSource();
      }
    }

    final h = horizontal ?? '0';
    final v = vertical ?? '0';

    // Both zero → EdgeInsets.zero
    if (_isZeroSource(h) && _isZeroSource(v)) {
      rule.reportAtNode(node, arguments: ['EdgeInsets.zero']);
      return;
    }

    // Both equal → EdgeInsets.all(v)
    if (h == v) {
      rule.reportAtNode(node, arguments: ['EdgeInsets.all($h)']);
    }
  }

  void _checkAll(Expression node, ArgumentList argumentList) {
    final args = argumentList.arguments;
    if (args.isEmpty) return;

    final value = args.first.toSource();
    if (_isZeroSource(value)) {
      rule.reportAtNode(node, arguments: ['EdgeInsets.zero']);
    }
  }

  static bool _isZeroSource(String source) {
    return source == '0' || source == '0.0';
  }
}
