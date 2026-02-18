// ignore_for_file: unused_local_variable

// avoid_incomplete_copy_with
//
// Warns when a copyWith method does not include all parameters from the
// class's default constructor.

// ❌ Bad: copyWith is missing the 'surname' parameter
class IncompletePerson {
  const IncompletePerson({required this.name, required this.surname});

  final String name;
  final String surname;

  // LINT: Missing constructor parameters: surname
  IncompletePerson copyWith({String? name}) {
    return IncompletePerson(name: name ?? this.name, surname: surname);
  }
}

// ❌ Bad: copyWith is missing both 'port' and 'path'
class IncompleteConfig {
  const IncompleteConfig({
    required this.host,
    required this.port,
    required this.path,
  });

  final String host;
  final int port;
  final String path;

  // LINT: Missing constructor parameters: port, path
  IncompleteConfig copyWith({String? host}) {
    return IncompleteConfig(host: host ?? this.host, port: port, path: path);
  }
}

// ✅ Good: copyWith includes all constructor parameters
class CompletePerson {
  const CompletePerson({required this.name, required this.surname});

  final String name;
  final String surname;

  CompletePerson copyWith({String? name, String? surname}) {
    return CompletePerson(
      name: name ?? this.name,
      surname: surname ?? this.surname,
    );
  }
}

// ✅ Good: No copyWith method — no warning
class NoCopyWith {
  const NoCopyWith({required this.value});

  final int value;
}
