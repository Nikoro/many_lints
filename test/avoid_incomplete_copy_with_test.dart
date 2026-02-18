import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_incomplete_copy_with.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidIncompleteCopyWithTest),
  );
}

@reflectiveTest
class AvoidIncompleteCopyWithTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidIncompleteCopyWith();
    super.setUp();
  }

  // --- Positive cases (should trigger lint) ---

  Future<void> test_missingSingleParameter() async {
    await assertDiagnostics(
      r'''
class Person {
  const Person({
    required this.name,
    required this.surname,
  });

  final String name;
  final String surname;

  Person copyWith({String? name}) {
    return Person(
      name: name ?? this.name,
      surname: surname,
    );
  }
}
''',
      [lint(145, 8)],
    );
  }

  Future<void> test_missingMultipleParameters() async {
    await assertDiagnostics(
      r'''
class Config {
  const Config({
    required this.host,
    required this.port,
    required this.path,
  });

  final String host;
  final int port;
  final String path;

  Config copyWith({String? host}) {
    return Config(
      host: host ?? this.host,
      port: port,
      path: path,
    );
  }
}
''',
      [lint(181, 8)],
    );
  }

  Future<void> test_emptyCopyWithParameters() async {
    await assertDiagnostics(
      r'''
class Item {
  const Item({required this.id});

  final int id;

  Item copyWith() {
    return Item(id: id);
  }
}
''',
      [lint(72, 8)],
    );
  }

  Future<void> test_positionalConstructorParams() async {
    await assertDiagnostics(
      r'''
class Point {
  final double x;
  final double y;

  Point(this.x, this.y);

  Point copyWith({double? x}) {
    return Point(x ?? this.x, y);
  }
}
''',
      [lint(85, 8)],
    );
  }

  // --- Negative cases (should NOT trigger lint) ---

  Future<void> test_allParametersPresent() async {
    await assertNoDiagnostics(r'''
class Person {
  const Person({
    required this.name,
    required this.surname,
  });

  final String name;
  final String surname;

  Person copyWith({String? name, String? surname}) {
    return Person(
      name: name ?? this.name,
      surname: surname ?? this.surname,
    );
  }
}
''');
  }

  Future<void> test_noCopyWithMethod() async {
    await assertNoDiagnostics(r'''
class Person {
  const Person({required this.name});

  final String name;
}
''');
  }

  Future<void> test_noDefaultConstructor() async {
    await assertNoDiagnostics(r'''
class Person {
  final String name;

  Person.create(this.name);

  Person copyWith({String? name}) {
    return Person.create(name ?? this.name);
  }
}
''');
  }

  Future<void> test_classWithNoConstructorParameters() async {
    await assertNoDiagnostics(r'''
class Empty {
  Empty();

  Empty copyWith() {
    return Empty();
  }
}
''');
  }

  Future<void> test_abstractClass() async {
    await assertNoDiagnostics(r'''
class Config {
  final String host;
  final int port;

  Config(this.host, this.port);

  Config copyWith({String? host, int? port}) {
    return Config(host ?? this.host, port ?? this.port);
  }
}
''');
  }

  Future<void> test_superFormalParams() async {
    await assertNoDiagnostics(r'''
class Base {
  final int id;
  Base(this.id);
}

class Child extends Base {
  final String name;
  Child(this.name, super.id);

  Child copyWith({String? name, int? id}) {
    return Child(name ?? this.name, id ?? this.id);
  }
}
''');
  }
}
