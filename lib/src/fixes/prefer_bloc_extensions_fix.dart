import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces `BlocProvider.of<T>(context)` with `context.read<T>()`
/// (or `context.watch<T>()` when `listen: true`).
class PreferBlocExtensionsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferBlocExtensions',
    DartFixKindPriority.standard,
    'Replace with context extension method',
  );

  PreferBlocExtensionsFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! MethodInvocation) return;

    final target = targetNode.target;
    if (target is! SimpleIdentifier) return;
    if (targetNode.methodName.name != 'of') return;

    // Determine context argument and listen flag
    final args = targetNode.argumentList.arguments;
    if (args.isEmpty) return;

    // First positional argument is the context
    final contextArg = args.first;
    if (contextArg is NamedExpression) return;
    final contextSource = contextArg.toSource();

    // Check for listen: true
    final hasListen = _hasListenTrue(targetNode.argumentList);
    final extensionMethod = hasListen ? 'watch' : 'read';

    // Preserve type arguments
    final typeArgs = targetNode.typeArguments?.toSource() ?? '';

    final replacement = '$contextSource.$extensionMethod$typeArgs()';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode), replacement);
    });
  }

  static bool _hasListenTrue(ArgumentList argumentList) {
    for (final arg in argumentList.arguments.whereType<NamedExpression>()) {
      if (arg.name.label.name == 'listen') {
        if (arg.expression case BooleanLiteral(value: true)) {
          return true;
        }
      }
    }
    return false;
  }
}
