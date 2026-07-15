import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces `x == ThemeMode.dark` with `x.isDark` (and `!=` with a
/// negated getter).
class PreferThemeModeGettersFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferThemeModeGetters',
    DartFixKindPriority.standard,
    'Replace with ThemeMode getter',
  );

  static const _getters = {
    'dark': 'isDark',
    'light': 'isLight',
    'system': 'isSystem',
  };

  PreferThemeModeGettersFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final expression = node.thisOrAncestorOfType<BinaryExpression>();
    if (expression == null) return;

    final (constant, value) = switch ((
      _constantName(expression.rightOperand),
      _constantName(expression.leftOperand),
    )) {
      (final String right, _) => (right, expression.leftOperand),
      (null, final String left) => (left, expression.rightOperand),
      _ => (null, null),
    };
    if (constant == null || value == null) return;

    final getter = _getters[constant];
    if (getter == null) return;

    final negated = expression.operator.lexeme == '!=';
    final needsParens =
        value is! SimpleIdentifier &&
        value is! PrefixedIdentifier &&
        value is! PropertyAccess &&
        value is! MethodInvocation;
    final target = needsParens ? '(${value.toSource()})' : value.toSource();
    final replacement = '${negated ? '!' : ''}$target.$getter';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(expression), replacement);
    });
  }

  static String? _constantName(Expression expression) {
    if (expression case PrefixedIdentifier(
      prefix: SimpleIdentifier(name: 'ThemeMode'),
      identifier: SimpleIdentifier(:final name),
    )) {
      return name;
    }
    return null;
  }
}
