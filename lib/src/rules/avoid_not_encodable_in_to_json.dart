import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidNotEncodableInToJson extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_not_encodable_in_to_json',
    "'{0}' is not JSON-encodable.",
    correctionMessage:
        "Convert the value first, for example with 'toIso8601String()', "
        "'.name', or a nested 'toJson()' call.",
  );

  AvoidNotEncodableInToJson()
    : super(
        name: 'avoid_not_encodable_in_to_json',
        description:
            'Warns when toJson returns a map holding values that jsonEncode '
            'cannot serialize.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidNotEncodableInToJson rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'toJson') return;

    final allowed = rule.config.stringListOption('allowed_types').toSet();

    for (final literal in _returnedMapLiterals(node.body)) {
      for (final element in literal.elements) {
        if (element is! MapLiteralEntry) continue;

        final value = element.value;
        final type = value.staticType;
        if (type == null) continue;
        if (_isEncodable(type, allowed)) continue;

        rule.reportAtNode(value, arguments: [type.getDisplayString()]);
      }
    }
  }

  Iterable<SetOrMapLiteral> _returnedMapLiterals(FunctionBody body) sync* {
    switch (body) {
      case ExpressionFunctionBody(:final expression):
        if (expression case final SetOrMapLiteral literal) yield literal;
      case BlockFunctionBody(:final block):
        final finder = _ReturnedMapFinder();
        block.accept(finder);
        yield* finder.found;
      default:
        return;
    }
  }

  bool _isEncodable(DartType type, Set<String> allowed) {
    if (type is DynamicType || type is InvalidType) return true;
    if (type.isDartCoreObject) return true;
    if (type is TypeParameterType) return true;

    if (type.isDartCoreNull ||
        type.isDartCoreNum ||
        type.isDartCoreInt ||
        type.isDartCoreDouble ||
        type.isDartCoreString ||
        type.isDartCoreBool) {
      return true;
    }

    if (allowed.contains(type.getDisplayString()) ||
        allowed.contains(type.element?.name)) {
      return true;
    }

    if (type is! InterfaceType) return false;

    if (type.isDartCoreList || type.isDartCoreSet) {
      final argument = type.typeArguments.firstOrNull;

      return argument == null || _isEncodable(argument, allowed);
    }

    if (type.isDartCoreMap) {
      final values = type.typeArguments.elementAtOrNull(1);

      return values == null || _isEncodable(values, allowed);
    }

    // Edge case: the default toEncodable of jsonEncode calls toJson
    return _declaresToJson(type);
  }

  bool _declaresToJson(InterfaceType type) {
    if (type.methods.any((m) => m.name == 'toJson')) return true;

    return type.element.allSupertypes.any(
      (supertype) => supertype.methods.any((m) => m.name == 'toJson'),
    );
  }
}

class _ReturnedMapFinder extends RecursiveAstVisitor<void> {
  final List<SetOrMapLiteral> found = [];

  @override
  void visitReturnStatement(ReturnStatement node) {
    if (node.expression case final SetOrMapLiteral literal) found.add(literal);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {} // Edge case: a closure's return is not ours
}
