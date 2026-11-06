import 'package:cloud_functions/cloud_functions.dart';
import '../experience_failure.dart';
import 'mirror_backend.dart';

abstract final class MirrorReviewService {
  static Future<void> send(Map<String, dynamic> feedback) async {
    try {
      final result = await MirrorBackend.functions
          .httpsCallable('submitMirrorReview')
          .call<Map<String, dynamic>>(feedback);
      if (result.data['status'] != 'saved') {
        throw const ExperienceFailure('Avis non enregistré.');
      }
    } on FirebaseFunctionsException {
      throw const ExperienceFailure(Friendly.review);
    }
  }
}
