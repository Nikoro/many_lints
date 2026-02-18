// ignore_for_file: unused_field, unused_element

// avoid_state_constructors
//
// Warns when a State subclass declares a constructor with a non-empty body
// or initializer list. Initialization logic should go into initState() instead.

import 'package:flutter/widgets.dart';

// ❌ Bad: Constructor with body
class BadWidget1 extends StatefulWidget {
  const BadWidget1({super.key});

  @override
  State<BadWidget1> createState() => _BadWidget1State();
}

class _BadWidget1State extends State<BadWidget1> {
  late String _data;

  // LINT: Constructor body should be empty — move logic to initState()
  _BadWidget1State() {
    _data = 'Hello';
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ❌ Bad: Constructor with initializer list
class BadWidget2 extends StatefulWidget {
  const BadWidget2({super.key});

  @override
  State<BadWidget2> createState() => _BadWidget2State();
}

class _BadWidget2State extends State<BadWidget2> {
  final String _data;

  // LINT: Initializer list in State constructor — move logic to initState()
  _BadWidget2State() : _data = 'Hello';

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: No constructor, initialization in initState()
class GoodWidget extends StatefulWidget {
  const GoodWidget({super.key});

  @override
  State<GoodWidget> createState() => _GoodWidgetState();
}

class _GoodWidgetState extends State<GoodWidget> {
  late String _data;

  @override
  void initState() {
    super.initState();
    _data = 'Hello';
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: Empty constructor is fine
class GoodWidget2 extends StatefulWidget {
  const GoodWidget2({super.key});

  @override
  State<GoodWidget2> createState() => _GoodWidget2State();
}

class _GoodWidget2State extends State<GoodWidget2> {
  _GoodWidget2State();

  @override
  Widget build(BuildContext context) => const SizedBox();
}
