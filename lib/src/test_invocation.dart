import 'package:analyzer/dart/ast/ast.dart';

const _testFunctions = {'test', 'testWidgets'};

const _groupFunctions = {'group'};

const _lifecycleFunctions = {'setUp', 'setUpAll', 'tearDown', 'tearDownAll'};

String? testInvocationKind(MethodInvocation node) {
  if (node.realTarget != null) return null;

  final name = node.methodName.name;
  if (_testFunctions.contains(name)) return 'test';
  if (_groupFunctions.contains(name)) return 'group';
  if (_lifecycleFunctions.contains(name)) return name;

  return null;
}

bool isTestOrGroupInvocation(MethodInvocation node) {
  if (node.realTarget != null) return false;

  final name = node.methodName.name;
  return _testFunctions.contains(name) || _groupFunctions.contains(name);
}

NamedArgument? namedArgument(MethodInvocation node, String name) {
  for (final argument in node.argumentList.arguments) {
    if (argument is NamedArgument && argument.name.lexeme == name) {
      return argument;
    }
  }

  return null;
}
