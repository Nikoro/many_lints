import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when a `ThemeMode` value is compared with `==`/`!=` against a
/// `ThemeMode` constant instead of using the dedicated getters added in
/// Flutter 3.44 (`isDark`, `isLight`, `isSystem`).
///
/// **Bad:**
/// ```dart
/// if (themeMode == ThemeMode.dark) { ... }
/// ```
///
/// **Good:**
/// ```dart
/// if (themeMode.isDark) { ... }
/// ```
class PreferThemeModeGetters extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_theme_mode_getters',
    'ThemeMode is compared against ThemeMode.{0}.',
    correctionMessage: 'Use the {1} getter instead.',
  );

  PreferThemeModeGetters()
    : super(
        name: 'prefer_theme_mode_getters',
        description:
            'Warns when a ThemeMode value is compared with == or != against '
            'a ThemeMode constant instead of using isDark/isLight/isSystem.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addBinaryExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferThemeModeGetters rule;

  _Visitor(this.rule);

  static const _themeModeChecker = TypeChecker.fromName(
    'ThemeMode',
    packageName: 'flutter',
  );

  static const _getters = {
    'dark': 'isDark',
    'light': 'isLight',
    'system': 'isSystem',
  };

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final operator = node.operator.lexeme;
    if (operator != '==' && operator != '!=') return;

    final constantName =
        _themeModeConstantName(node.rightOperand) ??
        _themeModeConstantName(node.leftOperand);
    if (constantName == null) return;

    final getter = _getters[constantName];
    if (getter == null) return;

    // Only report when the resolved ThemeMode enum actually declares the
    // getter (added in Flutter 3.44) so the fix cannot break older projects.
    final enumElement = _themeModeElement(node);
    if (enumElement == null ||
        !enumElement.getters.any((g) => g.name == getter)) {
      return;
    }

    rule.reportAtNode(node, arguments: [constantName, getter]);
  }

  /// Returns the constant name if [expression] is `ThemeMode.<constant>`.
  static String? _themeModeConstantName(Expression expression) {
    if (expression case PrefixedIdentifier(
      prefix: SimpleIdentifier(name: 'ThemeMode'),
      identifier: SimpleIdentifier(:final name),
    ) when _isThemeMode(expression.staticType)) {
      return name;
    }
    return null;
  }

  /// Resolves the `ThemeMode` enum element from either operand.
  static EnumElement? _themeModeElement(BinaryExpression node) {
    for (final operand in [node.leftOperand, node.rightOperand]) {
      final type = operand.staticType;
      if (type is InterfaceType && _isThemeMode(type)) {
        final element = type.element;
        if (element is EnumElement) return element;
      }
    }
    return null;
  }

  static bool _isThemeMode(DartType? type) =>
      type != null && _themeModeChecker.isExactlyType(type);
}
