import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when a `GestureDetector` widget is created without any event handler
/// callbacks, making it functionally useless.
class AvoidUnnecessaryGestureDetector extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_gesture_detector',
    "This 'GestureDetector' has no event handlers.",
    correctionMessage:
        'Try passing an event handler (e.g. onTap) or removing this widget.',
  );

  AvoidUnnecessaryGestureDetector()
    : super(
        name: 'avoid_unnecessary_gesture_detector',
        description:
            'Warns when a GestureDetector has no event handler callbacks.',
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
  final AvoidUnnecessaryGestureDetector rule;

  _Visitor(this.rule);

  static const _gestureDetectorChecker = TypeChecker.fromName(
    'GestureDetector',
    packageName: 'flutter',
  );

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final element = node.constructorName.type.element;
    if (element == null || !_gestureDetectorChecker.isExactly(element)) return;

    if (!_hasEventHandler(node.argumentList)) {
      rule.reportAtNode(node.constructorName);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final type = node.staticType;
    if (type == null || !_gestureDetectorChecker.isExactlyType(type)) return;

    if (!_hasEventHandler(node.argumentList)) {
      rule.reportAtNode(node.methodName);
    }
  }

  static bool _hasEventHandler(ArgumentList argumentList) {
    return argumentList.arguments.whereType<NamedExpression>().any(
      (arg) => arg.name.label.name.startsWith('on'),
    );
  }
}
