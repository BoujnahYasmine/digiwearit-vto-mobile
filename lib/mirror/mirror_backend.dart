import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firebase_startup.dart';

/// Dev-only switch: point callables and auth to the local emulators.
///
/// Run with:
///   flutter run --dart-define=USE_FIREBASE_EMULATOR=true
///
/// When unset the app uses the configured Firebase project (never changed by
/// this file). Facts about credentials and the Nano Banana key are never read
/// here; they stay server-side.
abstract final class MirrorBackend {
  static const bool useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');

  static FirebaseFunctions? _functions;
  static bool _authEmulatorConfigured = false;

  static FirebaseFunctions get functions {
    final instance = _functions ??= FirebaseFunctions.instanceFor(
      region: 'us-central1',
    );
    if (useEmulator) {
      instance.useFunctionsEmulator('127.0.0.1', 5001);
    }
    return instance;
  }

  /// Must be called before calling any callable or signing in: initializes
  /// Firebase (FirebaseStartup) and arms the emulator switch when requested.
  static Future<void> ensureReady() async {
    await FirebaseStartup.ensureReady();
    if (useEmulator) {
      functions;
      await prepareAuth();
    }
  }

  /// Must be called before any sign-in when using the auth emulator.
  static Future<void> prepareAuth() async {
    if (!useEmulator || _authEmulatorConfigured) return;
    await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
    _authEmulatorConfigured = true;
  }
}
