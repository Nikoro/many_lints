import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';

/// Warns when one `build` method creates more widgets than the configured
/// budget.
///
/// This is the breadth counterpart to [AvoidDeepWidgetNesting]. A tree can be
/// shallow and still be too much for one method: thirty widgets in one `build`
/// is a screen, a card, a header and a footer sharing a single scope, where
/// nothing has a name and nothing can be reused or tested on its own.
///
/// The limit is `max_widgets`, defaulting to 20. Only widget instantiations
/// are counted, and each one counts once regardless of depth.
///
/// Widgets built inside a `builder:` closure are counted separately, since
/// that closure is its own build function — the same reason
/// [AvoidDeepWidgetNesting] restarts its depth there.
class AvoidTooManyWidgetsPerBuild extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_too_many_widgets_per_build',
    'This build method creates {0} widgets, over the limit of {1}.',
    correctionMessage:
        'Extract a part of the tree into its own widget, so each has a name.',
  );

  AvoidTooManyWidgetsPerBuild()
    : super(
        name: 'avoid_too_many_widgets_per_build',
        description:
            'Warns when one build method creates more widgets than the '
            'configured budget.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodDeclaration(this, _Visitor(this));
  }
}

/// Enough for a real screen; past it a build is several widgets in one.
const _defaultMaxWidgets = 20;

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidTooManyWidgetsPerBuild rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!_isBuildMethod(node)) return;

    final maxWidgets = rule.config.intOption(
      'max_widgets',
      defaultValue: _defaultMaxWidgets,
    );

    final counter = _WidgetCounter();
    node.body.accept(counter);

    if (counter.count <= maxWidgets) return;

    rule.reportAtToken(
      node.name,
      arguments: ['${counter.count}', '$maxWidgets'],
    );
  }

  /// Whether [node] is a widget-building method.
  ///
  /// Matched on the return type rather than the name, so `build`,
  /// `buildHeader` and a `Widget _row()` helper are all measured, while a
  /// `build` that returns something else (a `BuildResult` in a non-Flutter
  /// class) is not.
  bool _isBuildMethod(MethodDeclaration node) {
    final returnType = node.returnType?.type;
    return returnType != null && widgetChecker.isAssignableFromType(returnType);
  }
}

/// Counts widget instantiations, not descending into a nested closure — a
/// `builder:` is its own build function and is measured on its own terms.
class _WidgetCounter extends RecursiveAstVisitor<void> {
  int count = 0;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // A builder callback builds its own subtree, so its widgets are not more
    // of this method's.
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.staticType;
    if (type != null && widgetChecker.isAssignableFromType(type)) count++;

    super.visitInstanceCreationExpression(node);
  }
}
