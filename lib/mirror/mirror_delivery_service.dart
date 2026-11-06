import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import '../experience_failure.dart';
import 'mirror_backend.dart';

abstract final class MirrorDeliveryService {
  static Future<void> send(
    String email,
    Uint8List bytes,
    String requestId,
  ) async {
    try {
      final response = await MirrorBackend.functions
          .httpsCallable(
            'sendMirrorPhoto',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 90)),
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
        'unauthenticated' || 'permission-denied' => Friendly.mirrorReconnect,
        'invalid-argument' => Friendly.emailInvalid,
        'failed-precondition' => Friendly.emailInProgress,
        'resource-exhausted' => Friendly.emailTooManyTries,
        _ => Friendly.emailNotSent,
      });
    }
  }
}
