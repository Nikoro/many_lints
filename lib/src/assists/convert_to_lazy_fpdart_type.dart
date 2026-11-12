import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import '../fpdart_type_checkers.dart';
import '../type_checker.dart';

enum _Wrapper {
  either(checker: eitherChecker, target: 'TaskEither', arity: 2),
  option(checker: optionChecker, target: 'TaskOption', arity: 1);

  const _Wrapper({
    required this.checker,
    required this.target,
    required this.arity,
  });

  final TypeChecker checker;

  final String target;

  final int arity;
}

enum _Shape { futureOfWrapper, wrapper }

typedef _Source = ({_Wrapper wrapper, _Shape shape});

class ConvertToLazyFpdartType extends ResolvedCorrectionProducer {
  static const _assistKind = AssistKind(
    'many_lints.assist.convertToLazyFpdartType',
    30,
    "Convert to '{0}'",
  );

  static const _futureChecker = TypeChecker.fromUrl('dart:async#Future');

  ConvertToLazyFpdartType({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _assistKind;

  @override
  List<String> assistArguments = const [];

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final function = _enclosingFunction();
    if (function == null) return;

    final (:returnType, :body) = function;

    if (body.isGenerator) return;

    final source = _sourceOf(returnType.type);
    if (source == null) return;

    final arguments = _typeArgumentsOf(returnType, source.wrapper);
    if (arguments == null) return;

    assistArguments = [source.wrapper.target];

    final replacement = _replacementBody(body, source);
    if (replacement == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        SourceRange(returnType.offset, returnType.length),
        '${source.wrapper.target}<$arguments>',
      );
      builder.addSimpleReplacement(
        SourceRange(body.offset, body.length),
        replacement,
      );
    });
  }

  String? _replacementBody(FunctionBody body, _Source source) {
    final indent = _leadingWhitespaceOf(body.offset);

    if (body is BlockFunctionBody) {
      // Edge case: toSource() drops line breaks, so the block's original text is copied
      final block = _reindented(body.block, indent);
      return '=> ${source.wrapper.target}(() async $block);';
    }

    if (body is ExpressionFunctionBody) {
      final expression = body.expression.toSource();

      // Edge case: wrapping a future thunk in `async` would only add a redundant hop
      final thunk =
          source.shape == _Shape.futureOfWrapper && !body.isAsynchronous
          ? '() => $expression'
          : '() async => $expression';

      return '=> ${source.wrapper.target}($thunk);';
    }

    return null;
  }

  String _reindented(Block block, String indent) {
    final content = unitResult.content;
    final original = content.substring(block.offset, block.end);

    return original
        .split('\n')
        .map((line) => line.isEmpty ? line : '$indent    $line')
        .join('\n')
        .trimLeft();
  }

  ({TypeAnnotation returnType, FunctionBody body})? _enclosingFunction() {
    for (AstNode? current = node; current != null; current = current.parent) {
      switch (current) {
        case MethodDeclaration(:final returnType?, :final body):
          return (returnType: returnType, body: body);
        case FunctionDeclaration(
          :final returnType?,
          functionExpression: FunctionExpression(:final body),
        ):
          return (returnType: returnType, body: body);
        case FunctionExpression():
          return null;
      }
    }

    return null;
  }

  _Source? _sourceOf(DartType? type) {
    if (type == null) return null;

    for (final wrapper in _Wrapper.values) {
      if (wrapper.checker.isExactlyType(type)) {
        return (wrapper: wrapper, shape: _Shape.wrapper);
      }

      if (_futureChecker.isExactlyType(type) &&
          type is InterfaceType &&
          type.typeArguments.length == 1 &&
          wrapper.checker.isExactlyType(type.typeArguments.single)) {
        return (wrapper: wrapper, shape: _Shape.futureOfWrapper);
      }
    }

    return null;
  }

  String? _typeArgumentsOf(TypeAnnotation returnType, _Wrapper wrapper) {
    if (returnType is! NamedType) return null;

    final written = returnType.typeArguments?.arguments;
    if (written == null || written.isEmpty) return null;

    if (_futureChecker.isExactlyType(returnType.type!)) {
      final inner = written.single;
      return inner is NamedType ? _argumentsOf(inner, wrapper) : null;
    }

    return _argumentsOf(returnType, wrapper);
  }

  String? _argumentsOf(NamedType type, _Wrapper wrapper) {
    final arguments = type.typeArguments?.arguments;
    if (arguments == null || arguments.length != wrapper.arity) return null;

    return arguments.map((argument) => argument.toSource()).join(', ');
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
}
