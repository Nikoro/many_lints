import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../flutter_type_checkers.dart';

class UseClosestBuildContextFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.useClosestBuildContext',
    DartFixKindPriority.standard,
    "Rename inner parameter to use the closest BuildContext",
  );

  UseClosestBuildContextFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final SimpleIdentifier? targetNode = node
        .thisOrAncestorOfType<SimpleIdentifier>();
    if (targetNode == null) return;

    final outerContextName = targetNode.name;

    final closureParam = _findEnclosingBuildContextParam(targetNode);
    if (closureParam == null) return;

    final paramName = closureParam.name;
    if (paramName == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.token(paramName), outerContextName);
    });
  }

  FormalParameter? _findEnclosingBuildContextParam(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is FunctionExpression) {
        final parameters = current.parameters?.parameters;
        if (parameters != null) {
          for (final param in parameters) {
            if (_isBuildContextType(param)) return param;
          }
        }
        return null;
      }
      if (current is MethodDeclaration) return null;
      current = current.parent;
    }
    return null;
  }

  static bool _isBuildContextType(FormalParameter param) {
    final type = param.type?.type;
    if (type != null) return buildContextChecker.isExactlyType(type);

    // Edge case: an untyped closure parameter has no annotation, so the resolved type is read
    final element = param.declaredFragment?.element;
    if (element == null) return false;

    return buildContextChecker.isExactlyType(element.type);
  }
}
