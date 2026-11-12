import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../type_checker.dart';

class PreferThemeModeGetters extends ManyLintsRule {
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
  void registerManyLintsProcessors(
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

  static const _flutterOrMaterialUiThemeModeChecker = TypeChecker.any([
    TypeChecker.fromName('ThemeMode', packageName: 'flutter'),
    TypeChecker.fromName('ThemeMode', packageName: 'material_ui'),
  ]);

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

    final enumElement = _themeModeElement(node);
    final themeModeDeclaresGetter =
        enumElement?.getters.any((g) => g.name == getter) ?? false;
    if (!themeModeDeclaresGetter) return;

    rule.reportAtNode(node, arguments: [constantName, getter]);
  }

  static String? _themeModeConstantName(Expression expression) {
    if (expression case PrefixedIdentifier(
      prefix: SimpleIdentifier(name: 'ThemeMode'),
      identifier: SimpleIdentifier(:final name),
    ) when _isThemeMode(expression.staticType)) {
      return name;
    }
    return null;
  }

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
      type != null && _flutterOrMaterialUiThemeModeChecker.isExactlyType(type);
}
