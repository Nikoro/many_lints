import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../type_checker.dart';

/// Warns when an `async` declaration does not expose a non-nullable `Future`.
///
/// An `async` body always returns a future at runtime, but broad declarations
/// such as `dynamic`, `Object`, `FutureOr<T>` or a nullable `Future<T>?` hide
/// that fact from callers. A precise `Future<T>` return type makes the async
/// contract visible and prevents callers from accidentally treating the
/// result as an immediate value.
class PreferCorrectFutureReturnType extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_correct_future_return_type',
    'This async declaration should return a non-nullable Future.',
    correctionMessage: 'Change the return type to Future<T>.',
  );

  PreferCorrectFutureReturnType()
    : super(
        name: 'prefer_correct_future_return_type',
        description:
            'Warns when an async declaration hides its Future result behind '
            'an imprecise or nullable return type.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferCorrectFutureReturnType rule;

  _Visitor(this.rule);

  static const _futureChecker = TypeChecker.fromUrl('dart:async#Future');
  static const _futureOrChecker = TypeChecker.fromUrl('dart:async#FutureOr');
  static const _objectChecker = TypeChecker.fromUrl('dart:core#Object');

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _check(node.returnType, node.functionExpression.body);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _check(node.returnType, node.body);
  }

  void _check(TypeAnnotation? annotation, FunctionBody body) {
    if (!body.isAsynchronous || body.isGenerator || annotation == null) return;

    final type = annotation.type;
    if (type == null || type is VoidType || type is NeverType) return;

    if (_futureChecker.isExactlyType(type)) {
      if (type.nullabilitySuffix == NullabilitySuffix.question) {
        rule.reportAtNode(annotation);
      }
      return;
    }

    if (type is DynamicType ||
        _objectChecker.isExactlyType(type) ||
        _futureOrChecker.isExactlyType(type)) {
      rule.reportAtNode(annotation);
    }
  }
}
