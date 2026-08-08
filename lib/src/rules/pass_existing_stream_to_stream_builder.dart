import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../async_builder_utils.dart';
import '../type_checker.dart';

/// Warns when a `StreamBuilder` receives a newly created `Stream`.
///
/// Creating the stream inline means a new subscription is opened on every
/// rebuild while the previous one is discarded, which loses buffered events
/// and leaks the old subscription.
class PassExistingStreamToStreamBuilder extends ManyLintsRule {
  static const LintCode code = LintCode(
    'pass_existing_stream_to_stream_builder',
    'This creates a new Stream on every rebuild.',
    correctionMessage:
        'Store the Stream in a field (initialized in initState) or a '
        'provider, and pass that existing instance instead.',
  );

  PassExistingStreamToStreamBuilder()
    : super(
        name: 'pass_existing_stream_to_stream_builder',
        description:
            'Warns when a StreamBuilder is given a Stream created inline, '
            'which resubscribes on every rebuild.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PassExistingStreamToStreamBuilder rule;

  _Visitor(this.rule);

  static const _streamBuilderChecker = TypeChecker.fromName(
    'StreamBuilder',
    packageName: 'flutter',
  );

  static const _streamChecker = TypeChecker.fromUrl('dart:async#Stream');

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _check(node, node.argumentList);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // A constructor call without type arguments parses as a MethodInvocation.
    _check(node, node.argumentList);
  }

  void _check(Expression node, ArgumentList argumentList) {
    final type = node.staticType;
    if (type == null || !_streamBuilderChecker.isAssignableFromType(type)) {
      return;
    }

    final stream = namedArgument(argumentList.arguments, 'stream');
    if (stream == null) return;

    if (createsNewAsyncSource(stream, _streamChecker)) {
      rule.reportAtNode(stream);
    }
  }
}
