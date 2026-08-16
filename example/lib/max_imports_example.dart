// ignore_for_file: directives_ordering

// max_imports
//
// Detects a file importing more libraries than the configured budget.
// This example lowers the budget to 5 so the file stays readable:
//
//   max_imports:
//     max_imports: 5

// LINT: six imports, over the budget configured for this example
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

// ✅ Good: a file that depends on less is coupled to less. Split along the
// seams the import list already reveals — the widget file imports widgets,
// the repository file imports the client.
//
// Note that `export` directives are not counted, so a barrel file is never
// reported no matter how many libraries it re-exports.

Future<void>? pending;
final queue = Queue<int>();
final encoded = jsonEncode(<String, int>{});
final random = Random();
final bytes = Uint8List(0);
final out = stdout;
