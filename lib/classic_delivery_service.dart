import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'classic_tryon_analytics.dart';
import 'experience_failure.dart';
import 'firebase_startup.dart';

/// E-mail delivery of the public try-on, through the same mailbox and message
/// as the mirror (`sendClassicPhoto`), under the anonymous classic session.
abstract final class ClassicDeliveryService {
  static Future<void> send(
    String email,
    Uint8List bytes,
    String requestId,
  ) async {
    try {
      await FirebaseStartup.ensureReady();
      final app = await getClassicApp();
      final auth = FirebaseAuth.instanceFor(app: app);
      if (auth.currentUser == null) await auth.signInAnonymously();
      final response =
          await FirebaseFunctions.instanceFor(app: app, region: 'us-central1')
              .httpsCallable(
                'sendClassicPhoto',
                options: HttpsCallableOptions(
                  timeout: const Duration(seconds: 90),
                ),
              )
              .call<Map<String, dynamic>>({
                'email': email,
                'requestId': requestId,
                'imageBase64': base64Encode(bytes),
              });
      if (response.data['status'] != 'sent') {
        throw const ExperienceFailure(Friendly.emailNotSent);
      }
    } on FirebaseFunctionsException catch (error) {
      throw ExperienceFailure(switch (error.code) {
        'invalid-argument' => Friendly.emailInvalid,
        'failed-precondition' => Friendly.emailInProgress,
        'resource-exhausted' => Friendly.emailTooManyTries,
        _ => Friendly.emailNotSent,
      });
    } on FirebaseException {
      throw const ExperienceFailure(Friendly.emailNotSent);
    }
  }
}
