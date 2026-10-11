import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../core/config/app_config.dart';
import '../core/errors/app_failure.dart';
import '../features/settings/data/firebase_account_repository.dart';
import '../firebase_options.dart';

const _authEmulatorPort = 9099;
const _firestoreEmulatorPort = 8080;
const _functionsEmulatorPort = 5001;

bool _emulatorsConnected = false;

/// Initializes Firebase once per process. Safe to call again after a failure
/// (e.g. from a retry button) or after a hot restart.
Future<void> initializeFirebase(AppConfig config) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on UnsupportedError {
    throw const FirebaseNotConfiguredFailure();
  } on FirebaseException catch (e) {
    if (e.code == 'network-request-failed') throw const NetworkFailure();
    throw UnexpectedFailure(e);
  }

  if (config.useFirebaseEmulators && !_emulatorsConnected) {
    await FirebaseAuth.instance.useAuthEmulator(
      config.emulatorHost,
      _authEmulatorPort,
    );
    FirebaseFirestore.instance.useFirestoreEmulator(
      config.emulatorHost,
      _firestoreEmulatorPort,
    );
    FirebaseFunctions.instanceFor(
      region: functionsRegion,
    ).useFunctionsEmulator(config.emulatorHost, _functionsEmulatorPort);
    _emulatorsConnected = true;
  }
}
