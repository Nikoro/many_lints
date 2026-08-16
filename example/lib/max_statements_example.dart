// ignore_for_file: unused_local_variable, avoid_print
// ignore_for_file: many_lints/prefer_getter_over_method
// ignore_for_file: many_lints/member_ordering

// max_statements
//
// Detects a function executing more statements than the configured budget.
// This example lowers the budget to 8 so the file stays readable:
//
//   max_statements:
//     max_statements: 8

class BadExamples {
  // LINT: ten statements, over the budget configured for this example
  void handleSubmit() {
    final name = 'a';
    final email = 'b';
    final phone = 'c';
    print(name);
    print(email);
    print(phone);
    final payload = {'name': name};
    final response = payload.toString();
    print(response);
    print('done');
  }
}

class GoodExamples {
  // ✅ Good: each step has a name, and the top level reads as a summary
  void handleSubmit() {
    final input = _collect();
    if (input.isEmpty) return;

    _submit(input);
  }

  Map<String, String> _collect() => {'name': 'a', 'email': 'b'};

  void _submit(Map<String, String> input) => print(input);
}

class EdgeCases {
  // A callback carries its own budget rather than adding to the enclosing
  // function's — it is separate work, measured where it is declared.
  void withCallback(List<int> xs) {
    final total = xs.length;

    xs.forEach((x) {
      print(x);
      print(x + 1);
      print(x + 2);
      print(x + 3);
      print(x + 4);
      print(x + 5);
      print(x + 6);
      print(x + 7);
      print(x + 8);
    });
  }

  // An expression body has no statements to count.
  int get total => 1 + 2 + 3;
}
