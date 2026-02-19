// ignore_for_file: unused_local_variable, unused_element

// prefer_single_setstate
//
// Warns when a method in a State subclass contains multiple setState calls
// that could be merged into a single invocation. Multiple setState calls
// cause redundant rebuilds.

import 'package:flutter/widgets.dart';

// ❌ Bad: Multiple consecutive setState calls
class BadConsecutive extends StatefulWidget {
  const BadConsecutive({super.key});

  @override
  State<BadConsecutive> createState() => _BadConsecutiveState();
}

class _BadConsecutiveState extends State<BadConsecutive> {
  String _a = '';
  String _b = '';

  void _update() {
    // LINT: Multiple setState calls should be merged
    setState(() {
      _a = 'Hello';
    });
    setState(() {
      _b = 'World';
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ❌ Bad: Multiple non-consecutive setState calls
class BadNonConsecutive extends StatefulWidget {
  const BadNonConsecutive({super.key});

  @override
  State<BadNonConsecutive> createState() => _BadNonConsecutiveState();
}

class _BadNonConsecutiveState extends State<BadNonConsecutive> {
  String _a = '';
  String _b = '';

  void _update() {
    // LINT: Even with code in between, setState calls should be merged
    setState(() {
      _a = 'Hello';
    });
    debugPrint('between');
    setState(() {
      _b = 'World';
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: Single setState call with all mutations
class GoodMerged extends StatefulWidget {
  const GoodMerged({super.key});

  @override
  State<GoodMerged> createState() => _GoodMergedState();
}

class _GoodMergedState extends State<GoodMerged> {
  String _a = '';
  String _b = '';

  void _update() {
    setState(() {
      _a = 'Hello';
      _b = 'World';
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: setState in separate closures (different scopes)
class GoodSeparateClosures extends StatefulWidget {
  const GoodSeparateClosures({super.key});

  @override
  State<GoodSeparateClosures> createState() => _GoodSeparateClosuresState();
}

class _GoodSeparateClosuresState extends State<GoodSeparateClosures> {
  String _data = '';

  void _setup() {
    final callback1 = () {
      setState(() {
        _data = 'a';
      });
    };
    final callback2 = () {
      setState(() {
        _data = 'b';
      });
    };
    callback1();
    callback2();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: setState in different methods
class GoodDifferentMethods extends StatefulWidget {
  const GoodDifferentMethods({super.key});

  @override
  State<GoodDifferentMethods> createState() => _GoodDifferentMethodsState();
}

class _GoodDifferentMethodsState extends State<GoodDifferentMethods> {
  String _data = '';

  void _update1() {
    setState(() {
      _data = 'Hello';
    });
  }

  void _update2() {
    setState(() {
      _data = 'World';
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
