import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/avoid_not_encodable_in_to_json.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidNotEncodableInToJsonTest),
  );
}

@reflectiveTest
class AvoidNotEncodableInToJsonTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidNotEncodableInToJson();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_dateTimeValue() async {
    await assertDiagnostics(
      r'''
class Event {
  Event(this.createdAt);

  final DateTime createdAt;

  Map<String, dynamic> toJson() => {'createdAt': createdAt};
}
''',
      [lint(118, 9)],
    );
  }

  Future<void> test_nestedModelWithoutToJson() async {
    await assertDiagnostics(
      r'''
class Address {
  Address(this.city);

  final String city;
}

class User {
  User(this.address);

  final Address address;

  Map<String, dynamic> toJson() => {'address': address};
}
''',
      [lint(172, 7)],
    );
  }

  Future<void> test_blockBodyReturn() async {
    await assertDiagnostics(
      r'''
class Event {
  Event(this.createdAt);

  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {'createdAt': createdAt};
  }
}
''',
      [lint(128, 9)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_primitiveValues() async {
    await assertNoDiagnostics(r'''
class User {
  User(this.name, this.age, this.active);

  final String name;
  final int age;
  final bool active;

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'active': active,
  };
}
''');
  }

  Future<void> test_convertedValue() async {
    await assertNoDiagnostics(r'''
class Event {
  Event(this.createdAt);

  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'createdAt': createdAt.millisecondsSinceEpoch,
  };
}
''');
  }

  Future<void> test_nestedModelWithToJson() async {
    await assertNoDiagnostics(r'''
class Address {
  Address(this.city);

  final String city;

  Map<String, dynamic> toJson() => {'city': city};
}

class User {
  User(this.address);

  final Address address;

  Map<String, dynamic> toJson() => {'address': address};
}
''');
  }

  Future<void> test_listOfPrimitives() async {
    await assertNoDiagnostics(r'''
class User {
  User(this.tags);

  final List<String> tags;

  Map<String, dynamic> toJson() => {'tags': tags};
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_dynamicValueIsAllowed() async {
    await assertNoDiagnostics(r'''
class Payload {
  Payload(this.data);

  final dynamic data;

  Map<String, dynamic> toJson() => {'data': data};
}
''');
  }

  Future<void> test_listOfNonEncodableIsReported() async {
    await assertDiagnostics(
      r'''
class Event {
  Event(this.times);

  final List<DateTime> times;

  Map<String, dynamic> toJson() => {'times': times};
}
''',
      [lint(112, 5)],
    );
  }

  Future<void> test_otherMethodNameIsIgnored() async {
    await assertNoDiagnostics(r'''
class Event {
  Event(this.createdAt);

  final DateTime createdAt;

  Map<String, dynamic> toMap() => {'createdAt': createdAt};
}
''');
  }
}
