// ignore_for_file: unused_local_variable, unused_element

// avoid_banned_names
//
// Warns when a declaration uses a banned name. The rule reports nothing until
// you configure it — see the `avoid_banned_names` entry in
// example/many_lints.yaml, which bans a few names that say nothing about what
// they hold.

List<String> fetchUsers() => const ['ada', 'grace'];

void badExamples() {
  // LINT: 'data' says nothing the type did not already say.
  final data = fetchUsers();
  print(data.length);

  // LINT: 'temp' is banned too.
  final temp = 21;
  print(temp);
}

// LINT: banned as a class name.
class Manager {}

// LINT: banned as a parameter name.
void process(int temp) => print(temp);

// ✅ Good: name each declaration for what it actually holds.
void goodExamples() {
  final users = fetchUsers();
  final celsius = 21;
  print('${users.length} at $celsius');
}

class UserDirectory {
  const UserDirectory(this.users);

  final List<String> users;
}

void convert(int celsius) => print(celsius);

// 🔹 Edge case: matching is exact, so banning 'data' leaves these alone.
class DataSource {
  final String userData = '';
}

// 🔹 Edge case: only *declarations* are checked, never references. Renaming
// the declaration fixes every use, so reporting each reference would bury the
// one line you can act on.
