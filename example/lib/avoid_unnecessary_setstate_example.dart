// ignore_for_file: unused_local_variable, unused_element

// avoid_unnecessary_setstate
//
// Warns when setState is called inside initState, didUpdateWidget, or build
// where it is unnecessary. In these lifecycle methods, mutate state directly
// — the framework already schedules a build after they return.

import 'package:flutter/widgets.dart';

// ❌ Bad: setState in initState
class BadInitState extends StatefulWidget {
  const BadInitState({super.key});

  @override
  State<BadInitState> createState() => _BadInitStateState();
}

class _BadInitStateState extends State<BadInitState> {
  String _data = '';

  @override
  void initState() {
    super.initState();
    // LINT: Unnecessary setState in initState
    setState(() {
      _data = 'Hello';
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ❌ Bad: setState in didUpdateWidget
class BadDidUpdateWidget extends StatefulWidget {
  const BadDidUpdateWidget({super.key});

  @override
  State<BadDidUpdateWidget> createState() => _BadDidUpdateWidgetState();
}

class _BadDidUpdateWidgetState extends State<BadDidUpdateWidget> {
  String _data = '';

  @override
  void didUpdateWidget(BadDidUpdateWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // LINT: Unnecessary setState in didUpdateWidget
    setState(() {
      _data = 'updated';
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ❌ Bad: setState directly in build
class BadBuild extends StatefulWidget {
  const BadBuild({super.key});

  @override
  State<BadBuild> createState() => _BadBuildState();
}

class _BadBuildState extends State<BadBuild> {
  String _data = '';

  @override
  Widget build(BuildContext context) {
    // LINT: Unnecessary setState in build
    setState(() {
      _data = 'Hello';
    });
    return const SizedBox();
  }
}

// ✅ Good: Direct state assignment in initState
class GoodInitState extends StatefulWidget {
  const GoodInitState({super.key});

  @override
  State<GoodInitState> createState() => _GoodInitStateState();
}

class _GoodInitStateState extends State<GoodInitState> {
  String _data = '';

  @override
  void initState() {
    super.initState();
    _data = 'Hello'; // Assign directly — no setState needed
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: setState in async method
class GoodAsync extends StatefulWidget {
  const GoodAsync({super.key});

  @override
  State<GoodAsync> createState() => _GoodAsyncState();
}

class _GoodAsyncState extends State<GoodAsync> {
  String _data = '';

  Future<void> _loadData() async {
    final data = await Future.value('Hello');
    setState(() {
      _data = data; // OK — async method needs setState to trigger rebuild
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: setState in event handler callback inside build
class GoodCallback extends StatefulWidget {
  const GoodCallback({super.key});

  @override
  State<GoodCallback> createState() => _GoodCallbackState();
}

class _GoodCallbackState extends State<GoodCallback> {
  String _data = '';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _data = 'tapped'; // OK — event handler runs asynchronously
        });
      },
      child: const SizedBox(),
    );
  }
}
