// ignore_for_file: unused_element, unused_local_variable, unused_field
// The good/edge-case bodies below deliberately re-read a field that a local
// already holds; that is the point of the rule, so silence the overlap.
// ignore_for_file: many_lints/use_existing_variable

// require_atomic_async_updates
//
// Warns when a field is read before an await and written after it using the
// value read beforehand. The read and the write are not atomic, so a
// concurrent call can interleave and have its update silently discarded.

class _Repository {
  Future<void> save() async {}
  Future<int> fetch() async => 1;
}

final _repository = _Repository();

// ❌ Bad: read into a local, await, then write the stale local back
class _BadCounter {
  int _value = 0;

  Future<void> increment() async {
    final current = _value;
    await _repository.save();
    // LINT: `current` may be stale — another call may have written `_value`
    // while this one was suspended, and that update is lost here
    _value = current + 1;
  }
}

// ❌ Bad: a compound assignment reads the field before writing it, so a read
// taken before the await is still the basis of the update
class _BadCompoundCounter {
  int _value = 0;

  Future<void> increment() async {
    print(_value);
    await _repository.save();
    // LINT: `+=` reads `_value` that a concurrent call may have changed
    _value += 1;
  }
}

// ❌ Bad: the `this.` qualified form has the same hazard
class _BadQualifiedCounter {
  int _value = 0;

  Future<void> increment() async {
    final current = this._value;
    await _repository.save();
    // LINT: same lost update, written through `this.`
    this._value = current + 1;
  }
}

// ✅ Good: re-read the field after the await
class _GoodCounter {
  int _value = 0;

  Future<void> increment() async {
    await _repository.save();
    _value = _value + 1;
  }
}

// ✅ Good: an unconditional overwrite cannot lose an update
class _GoodOverwrite {
  int _value = 0;

  Future<void> load() async {
    final result = await _repository.fetch();
    _value = result;
  }
}

// ✅ Edge case: a synchronous method has no suspension point
class _SyncCounter {
  int _value = 0;

  void increment() {
    final current = _value;
    _value = current + 1;
  }
}

// ✅ Edge case: a static field is not per-instance state
class _StaticHolder {
  static int _value = 0;

  Future<void> increment() async {
    final current = _value;
    await _repository.save();
    _value = current + 1;
  }
}

// ✅ Edge case: another object's field is outside this method's control
class _Holder {
  int value = 0;
}

class _OtherObjectWriter {
  final _Holder _holder = _Holder();

  Future<void> run() async {
    final current = _holder.value;
    await _repository.save();
    _holder.value = current + 1;
  }
}

// ✅ Edge case: the write happens before the await, so nothing is stale
class _WriteBeforeAwait {
  int _value = 0;

  Future<void> increment() async {
    final current = _value;
    _value = current + 1;
    await _repository.save();
  }
}

// ✅ Edge case: the callback a write installs is not part of the value written
typedef _Callback = void Function();

class _Timer {
  const _Timer(this.callback);

  final _Callback callback;

  void cancel() {}
}

class _CancelThenReassign {
  _Timer? _timer;

  Future<void> restart() async {
    await _repository.save();
    _timer?.cancel();
    _timer = _Timer(() => _timer?.cancel());
  }
}
