// ignore_for_file: unused_local_variable, unused_element, unused_field

// check_for_equals_in_render_object_setters
//
// Warns when a RenderObject setter marks the object dirty without first
// checking whether the value changed. `updateRenderObject` assigns every
// property on every rebuild, so an unguarded setter relayouts the subtree
// each time — and can feed an endless layout/rebuild loop.

import 'package:flutter/rendering.dart';

// ❌ Bad: repaints even when the value is unchanged
class _BadPaintRender extends RenderBox {
  Color _color = const Color(0xFF000000);

  // LINT: no comparison before marking dirty
  set color(Color value) {
    _color = value;
    markNeedsPaint();
  }
}

// ❌ Bad: the layout variant is more expensive still
class _BadLayoutRender extends RenderBox {
  double _width = 0;

  // LINT: a full relayout on every rebuild
  set width(double value) {
    _width = value;
    markNeedsLayout();
  }
}

// ✅ Good: early return when nothing changed
class _GoodEarlyReturnRender extends RenderBox {
  Color _color = const Color(0xFF000000);

  set color(Color value) {
    if (_color == value) return;
    _color = value;
    markNeedsPaint();
  }
}

// ✅ Good: the wrapping form works too
class _GoodWrappedRender extends RenderBox {
  double _width = 0;

  set width(double value) {
    if (_width != value) {
      _width = value;
      markNeedsLayout();
    }
  }
}

// ✅ Good: `identical` counts as a guard for reference types
class _GoodIdenticalRender extends RenderBox {
  Object _payload = 0;

  set payload(Object value) {
    if (identical(_payload, value)) return;
    _payload = value;
    markNeedsPaint();
  }
}

// ✅ Edge case: a setter that never marks dirty has nothing to guard
class _PlainSetterRender extends RenderBox {
  int _value = 0;

  set value(int newValue) {
    _value = newValue;
  }
}
// ignore_for_file: many_lints/prefer_correct_setter_parameter_name
