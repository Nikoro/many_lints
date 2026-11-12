import 'package:analyzer/dart/ast/ast.dart';

import 'flutter_type_checkers.dart';
import 'riverpod_type_checkers.dart';

String? receiverKind(MethodInvocation node, String method) {
  if (node.methodName.name != method) return null;

  final target = node.realTarget;
  if (target == null) return null;

  final type = target.staticType;
  if (type == null) return null;

  if (riverpodRefChecker.isAssignableFromType(type)) return 'ref';
  if (buildContextChecker.isAssignableFromType(type)) return 'context';

  return null;
}
