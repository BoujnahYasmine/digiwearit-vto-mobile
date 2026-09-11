import 'experience_failure.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ExperienceSession {
  static String? _credential;
  static DateTime? _expires;
  static bool get covered =>
      _credential != null &&
      _expires != null &&
      _expires!.isAfter(DateTime.now());
  static String? get credential => covered ? _credential : null;
  static void personal() {
    _credential = null;
    _expires = null;
  }

  static Future<void> authenticate(String token) async {
    final response = await ExperienceApi.post('/partner/sessions', {
      'token': token,
    });
    final expiry = DateTime.tryParse(response['expiresAt'] as String? ?? '');
    final credential = response['sessionToken'] as String?;
    if (response['subscriptionActive'] != true ||
        credential == null ||
        credential.isEmpty ||
        expiry == null ||
        !expiry.isAfter(DateTime.now())) {
      throw const ExperienceFailure(
        'Token invalide ou abonnement expiré. Vérifiez votre token puis réessayez.',
      );
    }
    _credential = credential;
    _expires = expiry;
  }
}

class ExperienceApi {
  static const baseUrl = String.fromEnvironment('DIGIWEARIT_API_URL');
  static bool get configured => baseUrl.isNotEmpty;
  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    if (!configured) {
      throw const ExperienceFailure('Ce service n’est pas encore connecté.');
    }
    final response = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {
            'Content-Type': 'application/json',
            if (ExperienceSession.credential != null)
              'Authorization': 'Bearer ${ExperienceSession.credential}',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw ExperienceFailure(
        path == '/partner/sessions'
            ? 'Token invalide ou abonnement expiré. Vérifiez votre token puis réessayez.'
            : 'Votre session a expiré. Reconnectez-vous puis réessayez.',
      );
    }
    if (response.statusCode == 413) {
      throw const ExperienceFailure(
        'La photo est trop volumineuse. Recadrez-la ou choisissez une autre photo.',
      );
    }
    if (response.statusCode == 429) {
      throw const ExperienceFailure(
        'Trop de demandes. Patientez un moment puis réessayez.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const ExperienceFailure(
        'Le service est momentanément indisponible. Réessayez.',
      );
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

enum GenerationStatus { processing, completed, failed }

enum PaymentStatus { pending, processing, demoPaid, failed, covered }

class RevealGate {
  RevealGate({required bool covered})
    : payment = covered ? PaymentStatus.covered : PaymentStatus.pending;
  GenerationStatus generation = GenerationStatus.processing;
  PaymentStatus payment;
  bool get canReveal =>
      generation == GenerationStatus.completed &&
      (payment == PaymentStatus.demoPaid || payment == PaymentStatus.covered);
}
