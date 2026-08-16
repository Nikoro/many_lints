import 'package:many_lints/src/rules/prefer_correct_handler_name.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferCorrectHandlerNameTest),
  );
}

@reflectiveTest
class PreferCorrectHandlerNameTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferCorrectHandlerName();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_handlerWithoutPrefix() async {
    await assertDiagnostics(
      r'''
class Button {
  Button({void Function()? onTap});
}

class C {
  void _submit() {}

  Button build() => Button(onTap: _submit);
}
''',
      [lint(119, 7)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_onPrefixedHandler() async {
    await assertNoDiagnostics(r'''
class Button {
  Button({void Function()? onTap});
}

class C {
  void _onTap() {}

  Button build() => Button(onTap: _onTap);
}
''');
  }

  Future<void> test_handlePrefixedHandler() async {
    await assertNoDiagnostics(r'''
class Button {
  Button({void Function()? onTap});
}

class C {
  void _handleTap() {}

  Button build() => Button(onTap: _handleTap);
}
''');
  }

  Future<void> test_closureIsNotATearOff() async {
    await assertNoDiagnostics(r'''
class Button {
  Button({void Function()? onTap});
}

class C {
  void submit() {}

  Button build() => Button(onTap: () => submit());
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_nonOnParameterIsNotAHandlerSlot() async {
    await assertNoDiagnostics(r'''
class Button {
  Button({void Function()? builder});
}

class C {
  void submit() {}

  Button build() => Button(builder: submit);
}
''');
  }

  Future<void> test_prefixMustStartANewWord() async {
    // `online` starts with `on` but is not an on-prefixed handler name.
    await assertDiagnostics(
      r'''
class Button {
  Button({void Function()? onTap});
}

class C {
  void _online() {}

  Button build() => Button(onTap: _online);
}
''',
      [lint(119, 7)],
    );
  }
}
