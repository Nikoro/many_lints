import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/list_all_equatable_fields.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(ListAllEquatableFieldsTest),
  );
}

@reflectiveTest
class ListAllEquatableFieldsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = ListAllEquatableFields();
    newPackage('equatable').addFile('lib/equatable.dart', r'''
abstract class Equatable {
  const Equatable();
  List<Object?> get props;
}

mixin EquatableMixin {
  List<Object?> get props;
}
''');
    super.setUp();
  }

  // --- Positive cases (should trigger lint) ---

  Future<void> test_missingOneField() async {
    await assertDiagnostics(
      r'''
import 'package:equatable/equatable.dart';

class Person extends Equatable {
  const Person(this.name, this.age);
  final String name;
  final int age;

  @override
  List<Object?> get props => [name];
}
''',
      [lint(155, 46)],
    );
  }

  Future<void> test_missingAllFields() async {
    await assertDiagnostics(
      r'''
import 'package:equatable/equatable.dart';

class Person extends Equatable {
  const Person(this.name, this.age);
  final String name;
  final int age;

  @override
  List<Object?> get props => [];
}
''',
      [lint(155, 42)],
    );
  }

  Future<void> test_missingFieldWithMixin() async {
    await assertDiagnostics(
      r'''
import 'package:equatable/equatable.dart';

class Person with EquatableMixin {
  Person(this.name, this.age);
  final String name;
  final int age;

  @override
  List<Object?> get props => [name];
}
''',
      [lint(151, 46)],
    );
  }

  Future<void> test_missingFieldBlockBody() async {
    await assertDiagnostics(
      r'''
import 'package:equatable/equatable.dart';

class Person extends Equatable {
  const Person(this.name, this.age);
  final String name;
  final int age;

  @override
  List<Object?> get props {
    return [name];
  }
}
''',
      [lint(155, 60)],
    );
  }

  // --- Negative cases (should NOT trigger lint) ---

  Future<void> test_allFieldsListed() async {
    await assertNoDiagnostics(r'''
import 'package:equatable/equatable.dart';

class Person extends Equatable {
  const Person(this.name, this.age);
  final String name;
  final int age;

  @override
  List<Object?> get props => [name, age];
}
''');
  }

  Future<void> test_allFieldsListedWithMixin() async {
    await assertNoDiagnostics(r'''
import 'package:equatable/equatable.dart';

class Person with EquatableMixin {
  Person(this.name, this.age);
  final String name;
  final int age;

  @override
  List<Object?> get props => [name, age];
}
''');
  }

  Future<void> test_nonListLiteralPropsBody() async {
    await assertNoDiagnostics(r'''
import 'package:equatable/equatable.dart';

class Person extends Equatable {
  const Person(this.name);
  final String name;

  @override
  List<Object?> get props => _buildProps();

  List<Object?> _buildProps() => [name];
}
''');
  }

  Future<void> test_staticFieldsIgnored() async {
    await assertNoDiagnostics(r'''
import 'package:equatable/equatable.dart';

class Person extends Equatable {
  const Person(this.name);
  final String name;
  static const maxAge = 120;

  @override
  List<Object?> get props => [name];
}
''');
  }

  Future<void> test_noFields() async {
    await assertNoDiagnostics(r'''
import 'package:equatable/equatable.dart';

class Empty extends Equatable {
  const Empty();

  @override
  List<Object?> get props => [];
}
''');
  }

  Future<void> test_notEquatable() async {
    await assertNoDiagnostics(r'''
class NotEquatable {
  final String name;
  NotEquatable(this.name);
}
''');
  }

  // --- Edge cases ---

  Future<void> test_blockBodyAllFieldsListed() async {
    await assertNoDiagnostics(r'''
import 'package:equatable/equatable.dart';

class Person extends Equatable {
  const Person(this.name, this.age);
  final String name;
  final int age;

  @override
  List<Object?> get props {
    return [name, age];
  }
}
''');
  }
}
