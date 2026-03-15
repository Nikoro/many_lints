import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:many_lints/src/ast_node_analysis.dart';
import 'package:test/test.dart';

/// Parses [code] and returns the first expression found in the first
/// function body.
Expression _parseExpression(String code) {
  final result = parseString(content: 'void f() { $code; }');
  final unit = result.unit;
  final fn = unit.declarations.first as FunctionDeclaration;
  final body = fn.functionExpression.body as BlockFunctionBody;
  final stmt = body.block.statements.first as ExpressionStatement;
  return stmt.expression;
}

/// Parses [code] as a top-level function and returns its body.
FunctionBody _parseFunctionBody(String fnCode) {
  final result = parseString(content: fnCode);
  final unit = result.unit;
  final fn = unit.declarations.first as FunctionDeclaration;
  return fn.functionExpression.body;
}

/// Parses [code] and returns the first class declaration.
ClassDeclaration _parseClass(String code) {
  final result = parseString(content: code);
  return result.unit.declarations.first as ClassDeclaration;
}

void main() {
  group('enclosingClassDeclaration', () {
    test('returns class when node is inside a class', () {
      final cls = _parseClass('''
class MyClass {
  void method() {}
}
''');
      final body = cls.body as BlockClassBody;
      final method = body.members.first as MethodDeclaration;
      final result = enclosingClassDeclaration(method);
      expect(result, isNotNull);
      expect(result!.namePart.typeName.lexeme, 'MyClass');
    });

    test('returns null when node is not inside a class', () {
      final parseResult = parseString(content: 'void topLevel() {}');
      final fn = parseResult.unit.declarations.first as FunctionDeclaration;
      final result = enclosingClassDeclaration(fn);
      expect(result, isNull);
    });
  });

  group('negateExpression', () {
    test('removes double negation', () {
      final expr = _parseExpression('!x');
      // The expression is PrefixExpression with BANG
      expect(negateExpression(expr), 'x');
    });

    test('simple identifier', () {
      final expr = _parseExpression('x');
      expect(negateExpression(expr), '!x');
    });

    test('prefixed identifier', () {
      final expr = _parseExpression('a.b');
      expect(negateExpression(expr), '!a.b');
    });

    test('method invocation', () {
      final expr = _parseExpression('list.isEmpty');
      expect(negateExpression(expr), '!list.isEmpty');
    });

    test('index expression', () {
      final expr = _parseExpression('list[0]');
      expect(negateExpression(expr), '!list[0]');
    });

    test('parenthesized expression', () {
      final expr = _parseExpression('(x)');
      expect(negateExpression(expr), '!(x)');
    });

    test('prefix expression (non-bang)', () {
      final expr = _parseExpression('-x');
      expect(negateExpression(expr), '!-x');
    });

    test('boolean literal', () {
      final expr = _parseExpression('true');
      expect(negateExpression(expr), '!true');
    });

    test('binary expression needs parentheses', () {
      final expr = _parseExpression('a && b');
      expect(negateExpression(expr), '!(a && b)');
    });

    test('property access', () {
      final expr = _parseExpression('(a).b');
      expect(negateExpression(expr), '!(a).b');
    });
  });

  group('buildEveryReplacement', () {
    test('returns null for non-FunctionExpression predicate', () {
      final expr = _parseExpression('myFunction');
      final result = buildEveryReplacement('list', expr);
      expect(result, isNull);
    });

    test('returns null for multi-statement body', () {
      final expr = _parseExpression('(e) { print(e); return e > 0; }');
      final result = buildEveryReplacement('list', expr);
      expect(result, isNull);
    });

    test('builds replacement with arrow body', () {
      final expr = _parseExpression('(e) => e > 0');
      final result = buildEveryReplacement('list', expr);
      expect(result, 'list.every((e) => !(e > 0))');
    });

    test('builds replacement with block return body', () {
      final expr = _parseExpression('(e) { return e > 0; }');
      final result = buildEveryReplacement('list', expr);
      expect(result, 'list.every((e) => !(e > 0))');
    });
  });

  group('maybeGetSingleReturnExpression', () {
    test('returns expression from arrow body', () {
      final body = _parseFunctionBody('int f() => 42;');
      final result = maybeGetSingleReturnExpression(body);
      expect(result, isNotNull);
      expect(result!.toSource(), '42');
    });

    test('returns expression from block with single return', () {
      final body = _parseFunctionBody('int f() { return 42; }');
      final result = maybeGetSingleReturnExpression(body);
      expect(result, isNotNull);
      expect(result!.toSource(), '42');
    });

    test('returns null for block with multiple statements', () {
      final body = _parseFunctionBody('int f() { print(1); return 42; }');
      final result = maybeGetSingleReturnExpression(body);
      expect(result, isNull);
    });

    test('returns null for empty block', () {
      final body = _parseFunctionBody('void f() {}');
      final result = maybeGetSingleReturnExpression(body);
      expect(result, isNull);
    });
  });
}
