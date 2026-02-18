// ignore_for_file: unused_local_variable

// prefer_class_destructuring
//
// Warns when multiple properties of the same object are accessed separately
// and could be consolidated using Dart 3 class destructuring.

class UserProfile {
  final String name;
  final String email;
  final int age;
  final String address;

  const UserProfile({
    required this.name,
    required this.email,
    required this.age,
    required this.address,
  });
}

// ❌ Bad: Accessing 3+ properties separately on the same variable
void displayUser(UserProfile user) {
  // LINT: Consider using class destructuring for 3 property accesses on 'user'
  final greeting = 'Hello, ${user.name}';
  final contact = user.email;
  print('Age: ${user.age}');
}

// ❌ Bad: Same pattern with local variable
void processUser() {
  final user = UserProfile(
    name: 'Alice',
    email: 'alice@example.com',
    age: 30,
    address: '123 Main St',
  );

  // LINT: 4 property accesses on 'user'
  print(user.name);
  print(user.email);
  print(user.age);
  print(user.address);
}

// ✅ Good: Using class destructuring
void displayUserGood(UserProfile user) {
  final UserProfile(:name, :email, :age) = user;
  final greeting = 'Hello, $name';
  final contact = email;
  print('Age: $age');
}

// ✅ Good: Only 2 property accesses (below threshold)
void showBasicInfo(UserProfile user) {
  print(user.name);
  print(user.email);
}

// ✅ Good: Method calls are not counted as property accesses
void interactWithUser(UserProfile user) {
  print(user.name);
  print(user.email);
  user.toString();
}
