// ignore_for_file: unused_element, unused_local_variable

// avoid_long_functions
//
// Warns when a function body exceeds the configured line budget. The default
// is 50 lines, counted between the braces.

// ❌ Bad: well past the budget, and doing several things at once
// LINT: this body is longer than max_lines
void badLongFunction() {
  final value1 = 1;
  final value2 = 2;
  final value3 = 3;
  final value4 = 4;
  final value5 = 5;
  final value6 = 6;
  final value7 = 7;
  final value8 = 8;
  final value9 = 9;
  final value10 = 10;
  final value11 = 11;
  final value12 = 12;
  final value13 = 13;
  final value14 = 14;
  final value15 = 15;
  final value16 = 16;
  final value17 = 17;
  final value18 = 18;
  final value19 = 19;
  final value20 = 20;
  final value21 = 21;
  final value22 = 22;
  final value23 = 23;
  final value24 = 24;
  final value25 = 25;
  final value26 = 26;
  final value27 = 27;
  final value28 = 28;
  final value29 = 29;
  final value30 = 30;
  final value31 = 31;
  final value32 = 32;
  final value33 = 33;
  final value34 = 34;
  final value35 = 35;
  final value36 = 36;
  final value37 = 37;
  final value38 = 38;
  final value39 = 39;
  final value40 = 40;
  final value41 = 41;
  final value42 = 42;
  final value43 = 43;
  final value44 = 44;
  final value45 = 45;
  final value46 = 46;
  final value47 = 47;
  final value48 = 48;
  final value49 = 49;
  final value50 = 50;
  final value51 = 51;
  final value52 = 52;
  final value53 = 53;
  final value54 = 54;
  final value55 = 55;
}

// ✅ Good: each part has its own name
void goodShortFunction() {
  _validate();
  _persist();
  _notify();
}

void _validate() {}
void _persist() {}
void _notify() {}
