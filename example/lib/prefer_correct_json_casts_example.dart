// ignore_for_file: unused_element, unused_local_variable

// prefer_correct_json_casts
//
// Warns when a value indexed out of a Map<String, dynamic> is cast to a
// non-nullable type. jsonDecode yields null for a missing key, and casting
// null to a non-nullable type throws a TypeError that never names the key.

// ❌ Bad: a missing key throws with no indication which one
class BadUser {
  BadUser.fromJson(Map<String, dynamic> json)
    // LINT: throws if 'name' is absent
    : name = json['name'] as String,
      // LINT: same for a numeric field
      age = json['age'] as int;

  final String name;
  final int age;
}

// ✅ Good: nullable cast plus an explicit fallback
class GoodUser {
  GoodUser.fromJson(Map<String, dynamic> json)
    : name = json['name'] as String? ?? '',
      age = json['age'] as int? ?? 0;

  final String name;
  final int age;
}

// ✅ Good: a nullable field keeps the nullable cast
class GoodOptional {
  GoodOptional.fromJson(Map<String, dynamic> json)
    : nickname = json['nickname'] as String?;

  final String? nickname;
}

// ✅ Edge case: a precisely typed map cannot yield null for a present key
String fromTypedMap(Map<String, String> json) => json['name'] as String;

// ✅ Edge case: a non-index read cannot be absent
num lengthOf(Map<String, dynamic> json) => json.length as num;

// ✅ Edge case: Object accepts null
Object asObject(Map<String, dynamic> json) => json['any'] as Object;
