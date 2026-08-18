import 'package:analyzer/dart/ast/ast.dart';

/// The `package:test` / `flutter_test` functions that declare a test.
const _testFunctions = {'test', 'testWidgets'};

/// The functions that declare a container of tests.
const _groupFunctions = {'group'};

/// The lifecycle hooks, which take the same `skip:` argument as a test.
const _lifecycleFunctions = {'setUp', 'setUpAll', 'tearDown', 'tearDownAll'};

/// A human-readable name for the kind of test declaration [node] is, or `null`
/// when it is not one.
///
/// Matching is by function name rather than by resolved element, because the
/// test package is a dev dependency: in a project that has not resolved it —
/// and in any analysis of a file outside a test — the invocation does not
/// resolve, and a rule keyed on the element would silently stop reporting
/// exactly where these rules are most needed.
///
/// The trade-off is a method named `test` on some unrelated object, which is
/// why a call with a target is rejected: `harness.test(...)` is not this.
String? testInvocationKind(MethodInvocation node) {
  if (node.realTarget != null) return null;

  final name = node.methodName.name;
  if (_testFunctions.contains(name)) return 'test';
  if (_groupFunctions.contains(name)) return 'group';
  if (_lifecycleFunctions.contains(name)) return name;

  return null;
}

/// Whether [node] declares a test or a group, excluding lifecycle hooks.
///
/// Focus applies only to things that can be selected to run; a `setUp` has no
/// `solo` of its own.
bool isTestOrGroupInvocation(MethodInvocation node) {
  if (node.realTarget != null) return false;

  final name = node.methodName.name;
  return _testFunctions.contains(name) || _groupFunctions.contains(name);
}

/// The named argument called [name] passed to [node], or `null`.
NamedArgument? namedArgument(MethodInvocation node, String name) {
  for (final argument in node.argumentList.arguments) {
    if (argument is NamedArgument && argument.name.lexeme == name) {
      return argument;
    }
  }

  return null;
}
