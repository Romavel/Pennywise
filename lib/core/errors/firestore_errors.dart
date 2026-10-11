import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_failure.dart';

/// Maps Firestore error codes to [DataFailure].
DataFailure mapFirestoreException(FirebaseException e) =>
    DataFailure(switch (e.code) {
      'permission-denied' ||
      'unauthenticated' => DataFailureCode.permissionDenied,
      'not-found' => DataFailureCode.notFound,
      'unavailable' || 'deadline-exceeded' => DataFailureCode.unavailable,
      _ => DataFailureCode.unknown,
    });
