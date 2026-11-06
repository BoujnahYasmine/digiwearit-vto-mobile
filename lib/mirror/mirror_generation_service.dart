import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';

import 'mirror_backend.dart';
import 'mirror_image_format.dart';

/// Result of a successful AI generation for a customer.
class MirrorGenerationResult {
  const MirrorGenerationResult({required this.requestId, required this.image});
  final String requestId;
  final Uint8List image;
}

/// A mirror generation failure. `code` is an opaque backend reason; the
/// message shown to customers is derived in the controller so that raw
/// exception text never reaches the UI.
class MirrorGenerationException implements Exception {
  MirrorGenerationException(this.code);
  final String? code;

  /// True when the network/request outcome is unknown and the same requestId
  /// should be reused (backend idempotency may already have processed it).
  bool get isUncertain {
    if (code == null) return true;
    switch (code!) {
      case 'NETWORK_ERROR':
      case 'GENERATION_IN_PROGRESS':
      case 'DEADLINE_EXCEEDED':
        return true;
    }
    return false;
  }
}

/// Gateway used by the try-on controller; tests inject fakes.
abstract interface class MirrorGenerationGateway {
  Future<MirrorGenerationResult> generate({
    required String outfitId,
    required Uint8List customerImage,
    bool allowMakeup = false,
    required String requestId,
  });
  String newRequestId();
}

/// Calls the backend generateMirrorTryOn callable. Only the requestId, the
/// outfitId and the upright customer image leave the device; the backend
/// resolves enterprise, subscription and quota.
class MirrorGenerationService implements MirrorGenerationGateway {
  MirrorGenerationService({FirebaseFunctions? functions})
    : _providedFunctions = functions;

  final FirebaseFunctions? _providedFunctions;
  FirebaseFunctions get _functions =>
      _providedFunctions ?? MirrorBackend.functions;

  /// Generates a request id matching the backend `/^[a-zA-Z0-9_-]{16,80}$/`
  /// contract.
  @override
  String newRequestId() {
    final random = Random.secure();
    final bytes = List<int>.generate(18, (_) => random.nextInt(256));
    final alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return bytes
        .map((byte) => alphabet[byte % alphabet.length])
        .join()
        .padLeft(16, '0');
  }

  @override
  Future<MirrorGenerationResult> generate({
    required String outfitId,
    required Uint8List customerImage,
    bool allowMakeup = false,
    required String requestId,
  }) async {
    try {
      final call = await _functions
          .httpsCallable(
            'generateMirrorTryOn',
            options: HttpsCallableOptions(
              timeout: const Duration(seconds: 150),
            ),
          )
          .call<Map<String, dynamic>>({
            'outfitId': outfitId,
            'requestId': requestId,
            'customerImage': base64Encode(customerImage),
            'allowMakeup': allowMakeup,
          });
      final imageBase64 = call.data['imageBase64'] as String?;
      if (imageBase64 == null || imageBase64.isEmpty) {
        throw MirrorGenerationException('AI_PROVIDER_ERROR');
      }
      return MirrorGenerationResult(
        requestId: call.data['requestId'] as String? ?? requestId,
        image: await matchCapturedFormat(
          base64Decode(imageBase64),
          customerImage,
        ),
      );
    } on FirebaseFunctionsException catch (error) {
      final details = error.details;
      final reason = details is Map
          ? details['reason']?.toString()
          : error.message;
      throw MirrorGenerationException(reason ?? codeFromHttp(error));
    } on MirrorGenerationException {
      rethrow;
    } on Object {
      throw MirrorGenerationException('NETWORK_ERROR');
    }
  }

  String codeFromHttp(FirebaseFunctionsException error) => switch (error.code) {
    'deadline-exceeded' => 'DEADLINE_EXCEEDED',
    'unavailable' || 'aborted' || 'internal' || 'unknown' => 'NETWORK_ERROR',
    'unauthenticated' => 'MIRROR_SESSION_REQUIRED',
    'permission-denied' => 'PERMISSION_DENIED',
    'failed-precondition' => 'FAILED_PRECONDITION',
    'already-exists' => 'GENERATION_IN_PROGRESS',
    'invalid-argument' => 'INVALID_ARGUMENT',
    _ => 'NETWORK_ERROR',
  };
}
