import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../many_lints_rule.dart';

class PreferBlocExtensions extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_bloc_extensions',
    "Use 'context.{0}' instead of '{1}.of()'.",
    correctionMessage: "Replace with 'context.{0}{2}()'.",
  );

  PreferBlocExtensions()
    : super(
        name: 'prefer_bloc_extensions',
        description:
            'Prefer context.read() / context.watch() over '
            'BlocProvider.of() / RepositoryProvider.of().',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferBlocExtensions rule;

  _Visitor(this.rule);

  static const _targetClasses = {'BlocProvider', 'RepositoryProvider'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'of') return;

    final target = node.target;
    if (target is! SimpleIdentifier) return;
    if (!_targetClasses.contains(target.name)) return;

    final element = target.element;
    if (element == null) return;
    final library = element.library;
    if (library == null) return;
    final libraryId = library.identifier;
    if (!libraryId.startsWith('package:flutter_bloc/') &&
        !libraryId.startsWith('package:provider/') &&
        !libraryId.startsWith('package:bloc/')) {
      return;
    }

    final hasListen = _hasListenTrue(node.argumentList);
    final extensionMethod = hasListen ? 'watch' : 'read';

    final typeArgs = node.typeArguments?.toSource() ?? '';

    rule.reportAtNode(
      node,
      arguments: [extensionMethod, target.name, typeArgs],
    );
  }

  static bool _hasListenTrue(ArgumentList argumentList) {
    final listen = namedArgumentValue(argumentList.arguments, 'listen');
    return listen is BooleanLiteral && listen.value;
  }
}
