import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Warns when the second argument of `expect()` or `expectLater()` is not a
/// `Matcher` subclass.
///
/// Using raw literals (e.g., `expect(x, 1)`) instead of matchers
/// (e.g., `expect(x, equals(1))`) leads to less informative failure messages.
///
/// **Bad:**
/// ```dart
/// expect(array.length, 1);
/// expect(value, 'hello');
/// expect(flag, true);
/// ```
///
/// **Good:**
/// ```dart
/// expect(array, hasLength(1));
/// expect(value, equals('hello'));
/// expect(flag, isTrue);
/// ```
class PreferTestMatchers extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_test_matchers',
    'Prefer using a Matcher instead of a literal value in expect().',
    correctionMessage:
        'Use a Matcher such as equals(), isTrue, or '
        'hasLength() instead of a literal value.',
  );

  PreferTestMatchers()
    : super(
        name: 'prefer_test_matchers',
        description:
            'Warns when expect() or expectLater() second argument is not a '
            'Matcher.',
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
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferTestMatchers rule;

  _Visitor(this.rule);

  static const _expectFunctions = {'expect', 'expectLater'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_expectFunctions.contains(node.methodName.name)) return;

    final args = node.argumentList.arguments;
    if (args.length < 2) return;

    final matcherExpr = args[1];

    // Skip if it's a named expression (e.g., reason: 'xxx')
    if (matcherExpr is NamedExpression) return;

    final matcherType = matcherExpr.staticType;
    if (matcherType == null || matcherType is DynamicType) return;

    // Check if the matcher type is a Matcher subclass
    if (_isMatcherType(matcherType)) return;

    rule.reportAtNode(matcherExpr);
  }

  /// Returns true if [type] is or extends `Matcher` from package:matcher.
  static bool _isMatcherType(DartType type) {
    if (type is! InterfaceType) return false;

    if (type.element.name == 'Matcher') return true;

    for (final supertype in type.element.allSupertypes) {
      if (supertype.element.name == 'Matcher') return true;
    }

    return false;
  }
}
