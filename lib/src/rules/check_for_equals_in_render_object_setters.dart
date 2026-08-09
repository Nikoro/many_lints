import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../type_checker.dart';

/// Warns when a `RenderObject` setter does not compare the new value with the
/// current one before marking the object dirty.
///
/// A setter that unconditionally calls `markNeedsLayout` or `markNeedsPaint`
/// schedules work even when nothing changed. `updateRenderObject` runs on
/// every rebuild and assigns every property, so an unguarded setter turns each
/// rebuild into a full relayout of that subtree.
///
/// At best this is wasted frames; when the layout itself triggers another
/// rebuild it becomes an endless loop.
///
/// **Bad:**
/// ```dart
/// set color(Color value) {
///   _color = value;
///   markNeedsPaint(); // runs even when the value is unchanged
/// }
/// ```
///
/// **Good:**
/// ```dart
/// set color(Color value) {
///   if (_color == value) return;
///   _color = value;
///   markNeedsPaint();
/// }
/// ```
class CheckForEqualsInRenderObjectSetters extends ManyLintsRule {
  static const LintCode code = LintCode(
    'check_for_equals_in_render_object_setters',
    "This setter marks the render object dirty without comparing '{0}' first.",
    correctionMessage:
        "Add an early return such as 'if (_field == value) return;' so an "
        'unchanged value does not schedule layout or paint work.',
  );

  CheckForEqualsInRenderObjectSetters()
    : super(
        name: 'check_for_equals_in_render_object_setters',
        description:
            'Warns when a RenderObject setter marks the object dirty without '
            'first checking whether the value actually changed.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final CheckForEqualsInRenderObjectSetters rule;

  _Visitor(this.rule);

  static const _renderObjectChecker = TypeChecker.fromName(
    'RenderObject',
    packageName: 'flutter',
  );

  /// The methods that schedule pipeline work; calling one is what makes an
  /// unguarded setter expensive.
  static const _markDirtyMethods = {
    'markNeedsLayout',
    'markNeedsPaint',
    'markNeedsCompositingBitsUpdate',
    'markNeedsSemanticsUpdate',
    'markNeedsLayoutForSizedByParentChange',
  };

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !_renderObjectChecker.isSuperOf(element)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    final markMethods = {
      ..._markDirtyMethods,
      ...rule.config.stringListOption('additional_methods'),
    };

    for (final member in body.members) {
      if (member is! MethodDeclaration) continue;
      if (!member.isSetter) continue;

      _checkSetter(member, markMethods);
    }
  }

  void _checkSetter(MethodDeclaration setter, Set<String> markMethods) {
    final body = setter.body;
    if (body is! BlockFunctionBody) return;

    final statements = body.block.statements;
    if (statements.isEmpty) return;

    final marks = _MarkDirtyFinder(markMethods);
    body.accept(marks);
    if (!marks.found) return;

    // Any comparison of the incoming value counts as a guard. This
    // deliberately over-accepts: the shapes vary (`==`, `identical`, a
    // `!=` early return, a nested field check), and a false positive on a
    // setter that *is* guarded is worse than missing an exotic one.
    final guards = _EqualityGuardFinder();
    body.accept(guards);
    if (guards.found) return;

    rule.reportAtToken(setter.name, arguments: [setter.name.lexeme]);
  }
}

/// Finds a call to one of the mark-dirty methods on this object.
class _MarkDirtyFinder extends RecursiveAstVisitor<void> {
  final Set<String> markMethods;
  bool found = false;

  _MarkDirtyFinder(this.markMethods);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    if ((target == null || target is ThisExpression) &&
        markMethods.contains(node.methodName.name)) {
      found = true;
    }
    super.visitMethodInvocation(node);
  }
}

/// Detects any equality comparison or `identical` call in a setter body.
class _EqualityGuardFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final operator = node.operator.lexeme;
    if (operator == '==' || operator == '!=') found = true;
    super.visitBinaryExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'identical') found = true;
    super.visitMethodInvocation(node);
  }
}
