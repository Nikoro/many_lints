import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import '../fpdart_type_checkers.dart';

/// Rewrites `x.chainFirst(effect)` to
/// `x.flatMap((value) => effect(value).map((_) => value))`, so a failing
/// effect fails the pipeline instead of being swallowed.
///
/// Two callback shapes are rewritten:
///
/// - a **tear-off** (`save`, `repo.save`, `this.save`) becomes a lambda that
///   calls it;
/// - a **one-expression lambda** (`(user) => save(user)`) keeps its parameter
///   and gets `.map((_) => user)` appended to its body, parenthesised when the
///   body binds looser than `.`. A wildcard parameter is renamed, since the
///   body must now return it.
///
/// Anything else — a block body, explicit type arguments, a callback computed
/// by an expression — is left alone: rewriting it would either change when
/// that expression is evaluated or need a guess at the types.
///
/// This changes behaviour on purpose (that is the point of the rule), so it is
/// offered one location at a time and never applied in bulk.
class AvoidChainFirstSwallowingFailureFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidChainFirstSwallowingFailure',
    DartFixKindPriority.standard,
    "Replace with 'flatMap' that propagates the effect's failure",
  );

  AvoidChainFirstSwallowingFailureFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final invocation = _chainFirstAt(node);
    if (invocation == null) return;
    if (invocation.typeArguments != null) return;

    final arguments = invocation.argumentList.arguments;
    if (arguments.length != 1) return;

    final callback = arguments.single.argumentExpression;
    final edit = switch (callback) {
      FunctionExpression() => _lambdaEdit(callback),
      SimpleIdentifier() || PrefixedIdentifier() => _tearOffEdit(callback),
      PropertyAccess(target: SimpleIdentifier() || ThisExpression()) =>
        _tearOffEdit(callback),
      _ => null,
    };
    if (edit == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        SourceRange(invocation.methodName.offset, invocation.methodName.length),
        'flatMap',
      );
      edit(builder);
    });
  }

  /// The fpdart `chainFirst` call at or above [node].
  MethodInvocation? _chainFirstAt(AstNode? node) {
    for (var current = node; current != null; current = current.parent) {
      if (current is! MethodInvocation) continue;
      if (current.methodName.name != 'chainFirst') continue;

      final type = current.realTarget?.staticType;
      if (type == null) return null;
      if (!failableFpdartChecker.isAssignableFromType(type)) return null;

      return current;
    }

    return null;
  }

  /// Wraps a tear-off in a lambda that calls it and keeps the value.
  void Function(DartFileEditBuilder)? _tearOffEdit(Expression tearOff) {
    final name = _freshName(tearOff);

    return (builder) => builder.addSimpleReplacement(
      SourceRange(tearOff.offset, tearOff.length),
      '($name) => ${tearOff.toSource()}($name).map((_) => $name)',
    );
  }

  /// Appends `.map((_) => parameter)` to a one-expression lambda's body.
  void Function(DartFileEditBuilder)? _lambdaEdit(FunctionExpression lambda) {
    if (lambda.typeParameters != null) return null;

    final body = lambda.body;
    if (body is! ExpressionFunctionBody) return null;
    if (body.keyword != null) return null;

    final parameters = lambda.parameters?.parameters;
    if (parameters == null || parameters.length != 1) return null;

    final parameter = parameters.single;
    if (parameter.isNamed) return null;

    final declared = parameter.name;
    if (declared == null) return null;

    final isWildcard = RegExp(r'^_+$').hasMatch(declared.lexeme);
    final name = isWildcard ? _freshName(body) : declared.lexeme;

    final expression = body.expression;
    final needsParentheses = expression.precedence < Precedence.postfix;

    return (builder) {
      if (isWildcard) {
        builder.addSimpleReplacement(
          SourceRange(declared.offset, declared.length),
          name,
        );
      }
      if (needsParentheses) builder.addSimpleInsertion(expression.offset, '(');
      builder.addSimpleInsertion(
        expression.end,
        '${needsParentheses ? ')' : ''}.map((_) => $name)',
      );
    };
  }

  /// `value`, or `value2`, `value3`... when [scope] already names it.
  String _freshName(AstNode scope) {
    final finder = _IdentifierNames();
    scope.accept(finder);

    var candidate = 'value';
    for (var suffix = 2; finder.names.contains(candidate); suffix++) {
      candidate = 'value$suffix';
    }

    return candidate;
  }
}

/// Collects every simple identifier name under a node.
class _IdentifierNames extends RecursiveAstVisitor<void> {
  final names = <String>{};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    names.add(node.name);
  }
}
