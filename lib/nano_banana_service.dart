import 'dart:async';
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'classic_tryon_analytics.dart';
import 'experience_failure.dart';
import 'firebase_startup.dart';
import 'try_on_request.dart';

/// Classic try-on generation through the `generateClassicTryOn` Cloud
/// Function: the server reads the outfit, builds the strict try-on prompt and
/// calls the AI model with its own credentials (no client API key, so App
/// Check enforcement on Firebase AI Logic does not block the public flow).
class NanoBananaService {
  NanoBananaService({
    Future<Map<String, dynamic>> Function(Map<String, dynamic>)? call,
  }) : _call = call ?? _callFunction;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>) _call;

  /// Data sent to the function: the outfit is referenced by id only.
  Map<String, dynamic> payload(TryOnRequest request) => {
    'outfitId': request.outfit.id,
    'customerImage': base64Encode(request.userPhotoBytes),
    'gender': request.gender,
    'style': request.style,
    'category': request.category,
    if (request.preferredColorName != null)
      'preferredColorName': request.preferredColorName,
  };

  Future<List<Uint8List>> generate(
    TryOnRequest request, {
    void Function(int)? onStage,
  }) async {
    final timer = Stopwatch()..start();
    var succeeded = false;
    try {
      onStage?.call(1);
      final Map<String, dynamic> response;
      try {
        response = await _call(payload(request));
      } on FirebaseFunctionsException catch (error) {
        debugPrint('Classic generation failed: ${error.code} ${error.details}');
        throw const ExperienceFailure(Friendly.generation);
      }
      final images = (response['images'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .map(base64Decode)
          .toList();
      if (images.isEmpty) {
        throw Exception(
          "Aucune image n'a pu être créée. Réessayez avec une photo plus nette.",
        );
      }
      succeeded = true;
      return images;
    } finally {
      timer.stop();
      await recordClassicTryOn(
        outfitId: request.outfit.id,
        outfitName: request.lookName,
        succeeded: succeeded,
        durationMs: timer.elapsedMilliseconds,
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint(
            "Classic statistics save is still pending in the background.",
          );
        },
      );
    }
  }

  static Future<Map<String, dynamic>> _callFunction(
    Map<String, dynamic> data,
  ) async {
    await FirebaseStartup.ensureReady();
    final app = await getClassicApp();
    final auth = FirebaseAuth.instanceFor(app: app);
    if (auth.currentUser == null) await auth.signInAnonymously();
    final response =
        await FirebaseFunctions.instanceFor(app: app, region: 'us-central1')
            .httpsCallable(
              'generateClassicTryOn',
              options: HttpsCallableOptions(
                timeout: const Duration(minutes: 3),
              ),
            )
            .call<Map<String, dynamic>>(data);
    return response.data;
  }
}
