import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when functional approaches (`.map().toList()`, `List.generate()`,
/// `.fold()`, spread with `.map()`) are used to build widget lists instead
/// of collection-for syntax.
class PreferForLoopInChildren extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_for_loop_in_children',
    'Prefer using a for-loop instead of functional list building.',
    correctionMessage:
        'Use collection-for syntax: [for (final item in items) Widget(item)].',
  );

  PreferForLoopInChildren()
    : super(
        name: 'prefer_for_loop_in_children',
        description:
            'Warns when .map().toList(), List.generate(), .fold(), or '
            'spread with .map() are used to build widget lists instead of '
            'collection-for syntax.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addListLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferForLoopInChildren rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;

    // Pattern 1: iterable.map((e) => ...).toList()
    if (methodName == 'toList') {
      _checkMapToList(node);
      return;
    }

    // Pattern 4: iterable.fold([], (list, e) { ... })
    if (methodName == 'fold') {
      _checkFold(node);
      return;
    }

    // Pattern 3: List.generate(n, (i) => ...) — parsed as MethodInvocation
    // when no type args
    if (methodName == 'generate') {
      _checkListGenerate(node);
      return;
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Pattern 3: List<Widget>.generate(n, (i) => ...) — parsed as
    // InstanceCreationExpression when type args are present
    final constructorName = node.constructorName;
    if (constructorName.name?.name == 'generate') {
      final typeName = constructorName.type.name.lexeme;
      if (typeName == 'List') {
        final args = node.argumentList.arguments;
        if (args.length >= 2 && args[1] is FunctionExpression) {
          rule.reportAtNode(node);
        }
      }
    }
  }

  @override
  void visitListLiteral(ListLiteral node) {
    // Pattern 2: [...iterable.map((e) => ...)]
    for (final element in node.elements) {
      if (element is SpreadElement) {
        _checkSpreadMap(element);
      }
    }
  }

  /// Pattern 1: `iterable.map((e) => ...).toList()`
  void _checkMapToList(MethodInvocation node) {
    // Skip if inside a spread — Pattern 2 handles that case
    if (node.parent is SpreadElement) return;

    final target = node.target;
    if (target is! MethodInvocation) return;
    if (target.methodName.name != 'map') return;

    final args = target.argumentList.arguments;
    if (args.isEmpty) return;
    if (args.first is! FunctionExpression) return;

    rule.reportAtNode(node);
  }

  /// Pattern 3: `List.generate(n, (i) => ...)` without type args
  void _checkListGenerate(MethodInvocation node) {
    final target = node.target;
    if (target is! SimpleIdentifier) return;
    if (target.name != 'List') return;

    // Verify it resolves to dart:core List
    final element = target.element;
    if (element == null) return;
    final library = element.library;
    if (library == null || !library.identifier.startsWith('dart:core')) return;

    final args = node.argumentList.arguments;
    if (args.length < 2) return;
    if (args[1] is! FunctionExpression) return;

    rule.reportAtNode(node);
  }

  /// Pattern 4: `iterable.fold([], (list, e) { list.add(...); return list; })`
  void _checkFold(MethodInvocation node) {
    final args = node.argumentList.arguments;
    if (args.length < 2) return;

    // First arg should be an empty list literal
    final initialValue = args.first;
    if (initialValue is! ListLiteral) return;
    if (initialValue.elements.isNotEmpty) return;

    // Second arg should be a function
    if (args[1] is! FunctionExpression) return;

    rule.reportAtNode(node);
  }

  /// Pattern 2: `...iterable.map((e) => ...)` inside a list literal,
  /// including `...iterable.map((e) => ...).toList()`
  void _checkSpreadMap(SpreadElement spread) {
    var expr = spread.expression;

    // Unwrap optional .toList()
    if (expr is MethodInvocation && expr.methodName.name == 'toList') {
      expr = expr.target!;
    }

    if (expr is! MethodInvocation) return;
    if (expr.methodName.name != 'map') return;

    final args = expr.argumentList.arguments;
    if (args.isEmpty) return;
    if (args.first is! FunctionExpression) return;

    rule.reportAtNode(spread);
  }
}
