// ignore_for_file: unused_element, unused_local_variable
// ignore_for_file: many_lints/prefer_type_over_var

// prefer_immediate_return
//
// Warns when a local variable is declared only to be returned on the next
// line. The name carries no information the return does not already give.

class _User {
  const _User(this.id);
  final String id;
}

class _Repository {
  Future<_User> fetchUser(String id) async => _User(id);
}

final _repository = _Repository();

// ❌ Bad: throwaway variables
int badFinal(int a) {
  // LINT: return the expression directly
  final result = a * 2;
  return result;
}

Future<_User> badAsync(String id) async {
  // LINT: same shape
  final user = await _repository.fetchUser(id);
  return user;
}

String badTyped(int a) {
  // LINT: the type annotation does not change anything
  final String label = 'value: $a';
  return label;
}

// ✅ Good: return directly
int goodDirect(int a) => a * 2;

Future<_User> goodAsync(String id) => _repository.fetchUser(id);

// ✅ Good: the variable is used more than once
int goodUsedTwice(int a) {
  final result = a * 2;
  print(result);
  return result;
}

// ✅ Good: the variable feeds another computation
int goodFeedsAnother(int a) {
  final doubled = a * 2;
  final result = doubled + 1;
  return doubled;
}

// ✅ Edge case: multiple variables in one declaration cannot be collapsed
int edgeCaseMultipleVariables(int a) {
  var first = a, second = a * 2;
  return second;
}

// ✅ Edge case: a statement sits between the declaration and the return
int edgeCaseStatementBetween(int a) {
  final result = a * 2;
  print('done');
  return result;
}
