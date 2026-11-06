import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'experience_failure.dart';

/// REST client for the shared Digiwearit services used by the public try-on
/// flow: e-mail delivery and rating feedback. There is no partner session; a
/// request is only reported as accepted when the backend confirms it.
class ExperienceApi {
  static const baseUrl = String.fromEnvironment('DIGIWEARIT_API_URL');
  static bool get configured => baseUrl.isNotEmpty;

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    if (!configured) {
      throw const ExperienceFailure(Friendly.generic);
    }
    final response = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const ExperienceFailure(Friendly.generic);
    }
    if (response.statusCode == 413) {
      throw const ExperienceFailure(
        'Cette photo est un peu lourde 📷 Reprenez-en une ou choisissez-en une autre.',
      );
    }
    if (response.statusCode == 429) {
      throw const ExperienceFailure(
        'Beaucoup de demandes en ce moment ⏳ Patientez un instant puis réessayez.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const ExperienceFailure(Friendly.generic);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<void> sendPhoto(
    String email,
    Uint8List bytes,
    String resultId,
  ) async {
    final result = await post('/deliveries', {
      'email': email,
      'imageBase64': base64Encode(bytes),
      'resultId': resultId,
    });
    if (result['status'] != 'sent') {
      throw const ExperienceFailure(
        'L’envoi de l’e-mail n’a pas été confirmé. Réessayez.',
      );
    }
  }
}
