// ignore_for_file: unused_element, unused_local_variable

// prefer_string_parse_extensions
//
// fpdart defines `toIntOption` as literally
// `Option.fromNullable(int.tryParse(this))`. Writing the composition out
// reimplements it, and puts the parse and its null handling at opposite ends
// of the line — which is where a mismatched variable hides.

import 'package:fpdart/fpdart.dart';

// ❌ Bad: this is `input.toIntOption`, spelled out
// LINT: use toIntOption
Option<int> badInt(String input) => Option.fromNullable(int.tryParse(input));

// ❌ Bad: same for double
// LINT: use toDoubleOption
Option<double> badDouble(String input) =>
    Option.fromNullable(double.tryParse(input));

// ✅ Good: the extension fpdart ships
Option<int> goodInt(String input) => input.toIntOption;

Option<double> goodDouble(String input) => input.toDoubleOption;

// ✅ Good: the Either variant when the failure must reach the caller
Either<String, int> goodEither(String input) =>
    input.toIntEither(() => 'not a number');

// ✅ Good: `radix:` does something no extension covers
Option<int> goodRadix(String input) =>
    Option.fromNullable(int.tryParse(input, radix: 16));

// ✅ Good: fromNullable of something that is not a parse
Option<String> goodPlainNullable(String? name) => Option.fromNullable(name);

// ✅ Good: a bare tryParse, no Option involved
int? goodBareParse(String input) => int.tryParse(input);
