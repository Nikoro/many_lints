// ignore_for_file: unused_local_variable, unused_element, unused_field
// ignore_for_file: many_lints/prefer_overriding_parent_equality, many_lints/prefer_immutable_bloc_state, many_lints/avoid_unnecessary_stateful_widgets, many_lints/prefer_returning_shorthands, many_lints/use_dedicated_media_query_methods, many_lints/avoid_default_tostring

// always_pass_global_key
//
// Warns when a GlobalKey is constructed inside build. `build` runs on every
// rebuild, so the key gets a new identity each time and Flutter discards the
// whole subtree it identifies — losing form contents, scroll position and
// every State below it.

import 'package:flutter/material.dart';

// ❌ Bad: a new key on every rebuild
class _BadForm extends StatelessWidget {
  const _BadForm();

  @override
  Widget build(BuildContext context) {
    // LINT: the subtree is rebuilt from scratch whenever this widget rebuilds
    final key = GlobalKey<FormState>();

    return Form(key: key, child: const SizedBox());
  }
}

// ❌ Bad: inline construction has the same effect
class _BadInlineForm extends StatelessWidget {
  const _BadInlineForm();

  @override
  Widget build(BuildContext context) {
    // LINT: still a fresh identity each frame
    return Form(key: GlobalKey<FormState>(), child: const SizedBox());
  }
}

// ✅ Good: the key lives in a State field, so it survives rebuilds
class _GoodForm extends StatefulWidget {
  const _GoodForm();

  @override
  State<_GoodForm> createState() => _GoodFormState();
}

class _GoodFormState extends State<_GoodForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(key: _formKey, child: const SizedBox());
  }
}

// ✅ Good: a LocalKey is compared by value, so creating it in build is correct
class _GoodValueKey extends StatelessWidget {
  const _GoodValueKey();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(key: ValueKey('stable'));
  }
}

// ✅ Edge case: construction outside build is not this rule's concern
class _KeyFactory {
  GlobalKey<FormState> create() => GlobalKey<FormState>();
}
