import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

const _parseGetters = {
  'int': 'toIntOption',
  'double': 'toDoubleOption',
  'num': 'toNumOption',
  'bool': 'toBoolOption',
};

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

    // Edge case: unwrapped, `a ?? b` would become `a ?? b.toIntOption`
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
