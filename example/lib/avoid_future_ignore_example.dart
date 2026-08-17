// ignore_for_file: unused_local_variable

// avoid_future_ignore
//
// Warns when Future.ignore() suppresses asynchronous errors without an
// adjacent comment explaining why that is intentional.

import 'dart:async';

void discardSaveError(Future<void> save) {
  save.ignore(); // LINT: This hides every error produced by the save operation.
}

void startSave(Future<void> save) {
  // The operation may run in the background, but failures stay observable.
  unawaited(save);
}

void discardObsoleteRequest(Future<void> request) {
  // The response is obsolete, including any failure it produces.
  request.ignore();
}
