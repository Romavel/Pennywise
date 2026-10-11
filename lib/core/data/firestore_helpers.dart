import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../errors/firestore_errors.dart';
import 'write_result.dart';

/// Default time to wait for the server before reporting a write as
/// [WriteResult.pendingSync]. Firestore keeps offline writes on the device
/// and their futures complete only once they reach the server.
const defaultAckTimeout = Duration(seconds: 8);

/// Runs a Firestore write and maps its outcome to [WriteResult] or a
/// [DataFailure].
Future<WriteResult> runFirestoreWrite(
  Future<void> Function() action, {
  Duration ackTimeout = defaultAckTimeout,
}) async {
  try {
    await action().timeout(ackTimeout);
    return WriteResult.saved;
  } on TimeoutException {
    return WriteResult.pendingSync;
  } on FirebaseException catch (e) {
    throw mapFirestoreException(e);
  }
}

/// Converts Firestore errors in a stream to [DataFailure]s.
StreamTransformer<T, T> mapFirestoreErrors<T>() =>
    StreamTransformer.fromHandlers(
      handleError: (error, stackTrace, sink) => sink.addError(
        error is FirebaseException ? mapFirestoreException(error) : error,
        stackTrace,
      ),
    );
