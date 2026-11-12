import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import '../ast_node_analysis.dart';
import '../fpdart_type_checkers.dart';

enum _Wrapper {
  either(success: 'right', failure: 'left'),
  taskEither(success: 'right', failure: 'left'),
  option(success: 'some', failure: 'none');

  const _Wrapper({required this.success, required this.failure});

  final String success;

  final String failure;
}

class ConvertTryCatchConstructorToTryStatement
    extends ResolvedCorrectionProducer {
  static const _assistKind = AssistKind(
    'many_lints.assist.convertTryCatchConstructorToTryStatement',
    30,
    "Expand 'tryCatch' into 'try'/'catch'",
  );

  ConvertTryCatchConstructorToTryStatement({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _assistKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final invocation = _enclosingTryCatch();
    if (invocation == null) return;

    final wrapper = _wrapperOf(invocation);
    if (wrapper == null) return;

    final body = _bodyExpandedBy(invocation);
    if (body == null) return;

    final arguments = invocation.argumentList.arguments;
    final expected = wrapper == _Wrapper.option ? 1 : 2;
    if (arguments.length != expected) return;

    final run = _callbackAt(arguments, 0);
    if (run == null) return;

    if (_parameterCountOf(run) != 0) return;

    final success = maybeGetSingleReturnExpression(run.body);
    if (success == null) return;

    final catchClause = wrapper == _Wrapper.option
        ? _optionCatchClause(wrapper)
        : _errorCatchClause(arguments, wrapper);
    if (catchClause == null) return;

    final awaitKeyword = wrapper == _Wrapper.taskEither ? 'await ' : '';
    final returned = '${wrapper.success}($awaitKeyword${success.toSource()})';

    final indent = _leadingWhitespaceOf(body.offset);
    final replacement = wrapper == _Wrapper.taskEither
        ? _taskEitherBody(
            returned,
            catchClause,
            indent,
            isBlock: body is BlockFunctionBody,
          )
        : _blockBody(returned, catchClause, indent);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        SourceRange(body.offset, body.length),
        replacement,
      );
    });
  }

  String _blockBody(String returned, _CatchClause clause, String indent) =>
      '{\n'
      '$indent  try {\n'
      '$indent    return $returned;\n'
      '$indent  } ${clause.source} {\n'
      '$indent    return ${clause.result};\n'
      '$indent  }\n'
      '$indent}';

  String _taskEitherBody(
    String returned,
    _CatchClause clause,
    String indent, {
    required bool isBlock,
  }) {
    final task =
        'TaskEither(() async {\n'
        '$indent      try {\n'
        '$indent        return $returned;\n'
        '$indent      } ${clause.source} {\n'
        '$indent        return ${clause.result};\n'
        '$indent      }\n'
        '$indent    })';

    return isBlock ? '{\n$indent  return $task;\n$indent}' : '=> $task;';
  }

  String _leadingWhitespaceOf(int offset) {
    final content = unitResult.content;
    if (offset <= 0) return '';

    final lineStart = content.lastIndexOf('\n', offset - 1) + 1;

    var end = lineStart;
    while (end < content.length &&
        (content[end] == ' ' || content[end] == '\t')) {
      end++;
    }

    return content.substring(lineStart, end);
  }

  InstanceCreationExpression? _enclosingTryCatch() {
    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is InstanceCreationExpression &&
          current.constructorName.name?.name == 'tryCatch') {
        return current;
      }

      // Edge case: an enclosing closure that is an argument of tryCatch is reached later
      if (current is FunctionExpression && !_isArgumentOfTryCatch(current)) {
        return null;
      }
    }

    return null;
  }

  bool _isArgumentOfTryCatch(FunctionExpression expression) {
    final argumentList = expression.parent;
    if (argumentList is! ArgumentList) return false;

    final invocation = argumentList.parent;
    return invocation is InstanceCreationExpression &&
        invocation.constructorName.name?.name == 'tryCatch';
  }

  _Wrapper? _wrapperOf(InstanceCreationExpression invocation) {
    final element = invocation.constructorName.element;
    if (element == null) return null;

    final owner = element.enclosingElement;
    if (eitherChecker.isExactly(owner)) return _Wrapper.either;
    if (taskEitherChecker.isExactly(owner)) return _Wrapper.taskEither;
    if (optionChecker.isExactly(owner)) return _Wrapper.option;

    return null;
  }

  FunctionBody? _bodyExpandedBy(InstanceCreationExpression invocation) {
    final parent = invocation.parent;

    if (parent is ExpressionFunctionBody &&
        parent.expression == invocation &&
        !parent.isAsynchronous &&
        !parent.isGenerator) {
      return parent;
    }

    if (parent is ReturnStatement && parent.expression == invocation) {
      final block = parent.parent;
      if (block is Block && block.statements.length == 1) {
        final body = block.parent;
        if (body is BlockFunctionBody &&
            !body.isAsynchronous &&
            !body.isGenerator) {
          return body;
        }
      }
    }

    return null;
  }

  FunctionExpression? _callbackAt(NodeList<Argument> arguments, int index) {
    final argument = arguments[index].argumentExpression.unParenthesized;
    return argument is FunctionExpression ? argument : null;
  }

  int _parameterCountOf(FunctionExpression callback) =>
      callback.parameters?.parameters.length ?? 0;

  _CatchClause? _optionCatchClause(_Wrapper wrapper) =>
      _CatchClause(source: 'catch (_)', result: '${wrapper.failure}()');

  _CatchClause? _errorCatchClause(
    NodeList<Argument> arguments,
    _Wrapper wrapper,
  ) {
    final onError = _callbackAt(arguments, 1);
    if (onError == null) return null;

    final parameters = onError.parameters?.parameters;
    if (parameters == null || parameters.isEmpty || parameters.length > 2) {
      return null;
    }

    final failure = maybeGetSingleReturnExpression(onError.body);
    if (failure == null) return null;

    final errorName = parameters.first.name?.lexeme;
    if (errorName == null) return null;

    final stackName = parameters.length == 2
        ? parameters[1].name?.lexeme
        : null;
    if (parameters.length == 2 && stackName == null) return null;

    // Edge case: a stack trace the body never reads would raise unused_catch_stack
    final keepsStack =
        stackName != null && _referencesName(onError.body, stackName);

    final catchSource = keepsStack
        ? 'catch ($errorName, $stackName)'
        : 'catch ($errorName)';

    return _CatchClause(
      source: catchSource,
      result: '${wrapper.failure}(${failure.toSource()})',
    );
  }

  bool _referencesName(FunctionBody body, String name) {
    final finder = _IdentifierFinder(name);
    body.accept(finder);
    return finder.found;
  }
}

class _CatchClause {
  final String source;

  final String result;

  const _CatchClause({required this.source, required this.result});
}

class _IdentifierFinder extends RecursiveAstVisitor<void> {
  final String name;
  bool found = false;

  _IdentifierFinder(this.name);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == name) found = true;
    super.visitSimpleIdentifier(node);
  }
}
