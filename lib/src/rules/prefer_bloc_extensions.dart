import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when `BlocProvider.of(context)` or `RepositoryProvider.of(context)`
/// is used instead of `context.read()` / `context.watch()` extensions.
///
/// Using context extensions is shorter, keeps the codebase consistent, and
/// makes it less likely to overlook the `listen` parameter.
///
/// ## Example
///
/// ❌ Bad:
/// ```dart
/// final bloc = BlocProvider.of<CounterBloc>(context);
/// final repo = RepositoryProvider.of<MyRepo>(context);
/// final bloc = BlocProvider.of<CounterBloc>(context, listen: true);
/// ```
///
/// ✅ Good:
/// ```dart
/// final bloc = context.read<CounterBloc>();
/// final repo = context.read<MyRepo>();
/// final bloc = context.watch<CounterBloc>();
/// ```
class PreferBlocExtensions extends AnalysisRule {
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
  void registerNodeProcessors(
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

    // Verify it resolves to flutter_bloc / bloc package
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

    // Determine if listen: true is passed
    final hasListen = _hasListenTrue(node.argumentList);
    final extensionMethod = hasListen ? 'watch' : 'read';

    // Build the type args string for the correction message
    final typeArgs = node.typeArguments?.toSource() ?? '';

    rule.reportAtNode(
      node,
      arguments: [extensionMethod, target.name, typeArgs],
    );
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
