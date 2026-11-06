import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

Future<FirebaseApp>? _statisticsApp;

/// Separate Firebase app for the public try-on's anonymous session, so it
/// never replaces the mirror/admin login on the default app.
Future<FirebaseApp> getClassicApp() => _statisticsApp ??=
    (() async {
      const name = 'classic-statistics';
      try {
        return Firebase.app(name);
      } on FirebaseException catch (_) {
        return Firebase.initializeApp(
          name: name,
          options: Firebase.app().options,
        );
      }
    })().catchError((Object error, StackTrace stack) {
      _statisticsApp = null;
      Error.throwWithStackTrace(error, stack);
    });

/// Independent anonymous session: never replaces the mirror/admin login.
/// Stores only attempt metadata, never customer photos or email.
Future<void> recordClassicTryOn({
  required String outfitId,
  required String outfitName,
  required bool succeeded,
  required int durationMs,
}) async {
  try {
    final app = await getClassicApp();
    final auth = FirebaseAuth.instanceFor(app: app);
    final user = auth.currentUser ?? (await auth.signInAnonymously()).user;
    if (user == null || !user.isAnonymous) return;
    await FirebaseFirestore.instanceFor(
      app: app,
    ).collection('classicTryOns').add({
      'uid': user.uid,
      'outfitId': outfitId.substring(0, outfitId.length.clamp(0, 128)),
      'outfitName': outfitName.substring(0, outfitName.length.clamp(0, 120)),
      'status': succeeded ? 'completed' : 'failed',
      'durationMs': durationMs.clamp(0, 3600000),
      'createdAt': FieldValue.serverTimestamp(),
    });
  } on FirebaseException catch (error) {
    debugPrint('Classic try-on statistics not saved: ${error.code}');
  } catch (_) {
    debugPrint('Classic try-on statistics not saved: unexpected error.');
  }
}
