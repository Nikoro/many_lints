import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// The getter that replaces each wrapped `tryParse` call.
///
/// Kept in step with the rule's own table by the tests: a receiver the rule
/// reports but this map does not know would simply offer no fix, so the two
/// drifting apart is visible rather than silent.
const _parseGetters = {
  'int': 'toIntOption',
  'double': 'toDoubleOption',
  'num': 'toNumOption',
  'bool': 'toBoolOption',
};

/// Fix that replaces a wrapped `tryParse` with fpdart's string extension.
///
/// `Option.fromNullable(int.tryParse(s))` becomes `s.toIntOption`. The parsed
/// expression is re-derived from the AST rather than read out of the
/// diagnostic, so rewording the message cannot break the fix.
///
/// Only the built-in receivers are rewritten. A project that adds its own
/// through `additional_parsers` still gets the warning, but no fix — the
/// extension it should use is that project's, and its name cannot be derived
/// reliably enough to edit code with.
class PreferStringParseExtensionsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferStringParseExtensions',
    DartFixKindPriority.standard,
    "Replace with the fpdart string extension",
  );

  PreferStringParseExtensionsFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossSingleFile;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final creation = node.thisOrAncestorOfType<InstanceCreationExpression>();
    if (creation == null) return;

    final arguments = creation.argumentList.arguments;
    if (arguments.length != 1) return;

    final argument = arguments.first;
    if (argument is! Expression) return;

    final parse = argument.unParenthesized;
    if (parse is! MethodInvocation) return;

    final target = parse.realTarget;
    if (target is! Identifier) return;

    final getter = _parseGetters[target.name];
    if (getter == null) return;

    final parseArguments = parse.argumentList.arguments;
    if (parseArguments.length != 1) return;

    final parsed = parseArguments.first;
    if (parsed is! Expression) return;

    // A parsed expression that binds looser than `.` needs parentheses, or
    // `a ?? b` would become `a ?? b.toIntOption` — a different expression.
    final source = parsed.toSource();
    final receiver =
        parsed is Identifier ||
            parsed is PropertyAccess ||
            parsed is PrefixedIdentifier ||
            parsed is MethodInvocation ||
            parsed is SimpleStringLiteral ||
            parsed is IndexExpression
        ? source
        : '($source)';

    await builder.addDartFileEdit(file, (builder) {
      builder.importLibrary(Uri.parse('package:fpdart/fpdart.dart'));
      builder.addSimpleReplacement(range.node(creation), '$receiver.$getter');
    });
  }
}
