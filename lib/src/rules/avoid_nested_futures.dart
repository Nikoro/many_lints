import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns about a `Future<Future<T>>` type annotation.
///
/// Dart flattens futures automatically: `await` on a nested future yields
/// the inner value in one step, and an `async` function returning
/// `Future<T>` produces `Future<T>`, never `Future<Future<T>>`. Writing the
/// nested type means the annotation does not describe what the code
/// actually produces, and callers get a type they cannot usefully await
/// twice.
class AvoidNestedFutures extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_nested_futures',
    'Nested futures are flattened automatically.',
    correctionMessage:
        "Declare the inner type directly, for example 'Future<T>' instead "
        "of 'Future<Future<T>>'.",
  );

  AvoidNestedFutures()
    : super(
        name: 'avoid_nested_futures',
        description:
            'Warns when a type annotation nests one Future inside another, '
            'which Dart flattens anyway.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addNamedType(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidNestedFutures rule;

  _Visitor(this.rule);

  static const _futureChecker = TypeChecker.any([
    TypeChecker.fromUrl('dart:async#Future'),
    TypeChecker.fromUrl('dart:async#FutureOr'),
  ]);

  @override
  void visitNamedType(NamedType node) {
    if (!_isFuture(node)) return;

    final typeArguments = node.typeArguments?.arguments;
    if (typeArguments == null || typeArguments.length != 1) return;

    final inner = typeArguments.first;
    if (inner is! NamedType) return;
    if (!_isFuture(inner)) return;

    rule.reportAtNode(node);
  }

  bool _isFuture(NamedType node) {
    final type = node.type;
    if (type == null) return false;
    return _futureChecker.isExactlyType(type);
  }
}
