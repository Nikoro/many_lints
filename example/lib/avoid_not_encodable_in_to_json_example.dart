// ignore_for_file: unused_element, unused_local_variable

// avoid_not_encodable_in_to_json
//
// Warns when a toJson map holds a value jsonEncode cannot serialize.
// jsonEncode accepts only num, String, bool, null, List and Map — anything
// else throws JsonUnsupportedObjectError, and only at encode time.

enum Status { active, inactive }

class Address {
  Address(this.city);

  final String city;

  Map<String, dynamic> toJson() => {'city': city};
}

class PlainAddress {
  PlainAddress(this.city);

  final String city;
}

// ❌ Bad: a DateTime cannot be encoded directly
class BadEvent {
  BadEvent(this.createdAt);

  final DateTime createdAt;

  // LINT: DateTime is not JSON-encodable
  Map<String, dynamic> toJson() => {'createdAt': createdAt};
}

// ❌ Bad: an enum is not encodable either
class BadTask {
  BadTask(this.status);

  final Status status;

  // LINT: enums need `.name` or `.index`
  Map<String, dynamic> toJson() => {'status': status};
}

// ❌ Bad: a nested model that declares no toJson
class BadUser {
  BadUser(this.address);

  final PlainAddress address;

  // LINT: PlainAddress has no toJson for jsonEncode to reach
  Map<String, dynamic> toJson() => {'address': address};
}

// ❌ Bad: a collection is only encodable when its contents are
class BadSchedule {
  BadSchedule(this.times);

  final List<DateTime> times;

  // LINT: List<DateTime> holds non-encodable elements
  Map<String, dynamic> toJson() => {'times': times};
}

// ✅ Good: primitives pass straight through
class GoodUser {
  GoodUser(this.name, this.age, this.active);

  final String name;
  final int age;
  final bool active;

  Map<String, dynamic> toJson() => {'name': name, 'age': age, 'active': active};
}

// ✅ Good: converted before being placed in the map
class GoodEvent {
  GoodEvent(this.createdAt, this.status);

  final DateTime createdAt;
  final Status status;

  Map<String, dynamic> toJson() => {
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
  };
}

// ✅ Good: a nested model with its own toJson
class GoodNested {
  GoodNested(this.address);

  final Address address;

  Map<String, dynamic> toJson() => {'address': address};
}

// ✅ Edge case: `dynamic` may hold something encodable at runtime
class DynamicPayload {
  DynamicPayload(this.data);

  final dynamic data;

  Map<String, dynamic> toJson() => {'data': data};
}

// ✅ Edge case: only `toJson` is inspected
class OtherMethodName {
  OtherMethodName(this.createdAt);

  final DateTime createdAt;

  Map<String, dynamic> toMap() => {'createdAt': createdAt};
}
