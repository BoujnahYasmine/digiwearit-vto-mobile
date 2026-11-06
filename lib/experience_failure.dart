import 'dart:async';

class ExperienceFailure implements Exception {
  const ExperienceFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// What customers read when something goes wrong: warm, short, and always
/// saying what to do next. Never codes, provider names or technical words;
/// details stay in the debug logs.
abstract final class Friendly {
  static const generic =
      'Un petit contretemps de notre côté 🙏 Réessayons dans un instant.';
  static const connection =
      'Votre connexion fait une petite pause 📶 Vérifiez le Wi-Fi ou les données, puis réessayez.';
  static const slow =
      'Ça prend un peu plus de temps que prévu ⏳ Réessayons dans un instant.';
  static const generation =
      'Votre essayage n’a pas pu être finalisé cette fois ✨ Réessayons, cela ne prend que quelques secondes.';
  static const outfitUnavailable =
      'Cette tenue vient de quitter la collection 👗 Choisissez-en une autre, il y a plein d’autres coups de cœur !';
  static const quota =
      'Tous les essayages du moment ont été utilisés ✨ Un conseiller peut vous aider à continuer.';
  static const servicePaused =
      'L’essayage virtuel fait une petite pause ici 🙂 Un conseiller peut vous aider.';
  static const mirrorReconnect =
      'Ce miroir doit être reconnecté 🙂 Un conseiller va s’en occuper.';
  static const cameraUnavailable =
      'La caméra ne répond pas pour le moment 📷 Réessayez, ou choisissez une photo de votre galerie.';
  static const cameraDenied =
      'Pour prendre votre photo, autorisez la caméra dans les réglages puis revenez ici 📷';
  static const photoUnreadable =
      'Cette photo n’a pas pu être ouverte 📷 Reprenez-en une ou choisissez-en une autre.';
  static const paymentFailed =
      'Le paiement n’a pas abouti, rien n’a été débité 💳 Vous pouvez réessayer.';
  static const paymentUnavailable =
      'Le paiement n’est pas disponible pour le moment 💳 Réessayez dans un instant.';
  static const emailInvalid =
      'Cette adresse e-mail semble incomplète ✉️ Vérifiez-la puis réessayez.';
  static const emailInProgress =
      'Votre photo est déjà en route ✉️ Pensez à regarder aussi dans vos spams.';
  static const emailTooManyTries =
      'Votre photo n’a pas pu partir après plusieurs essais ✉️ Réessayez un peu plus tard.';
  static const emailNotSent =
      'Votre photo n’est pas encore partie ✉️ Vérifiez votre connexion puis réessayez.';
  static const catalogue =
      'La collection met un peu de temps à arriver 👗 Vérifiez votre connexion puis réessayez.';
  static const review =
      'Votre avis n’a pas pu être envoyé, mais merci beaucoup 💜';
}

/// Customer-facing text for any [error]: our own friendly messages pass
/// through, slow or lost connections get their own advice, and everything
/// else becomes [fallback] (never the raw error).
String explainFailure(Object error, {String fallback = Friendly.generic}) {
  if (error is ExperienceFailure) return error.message;
  final text = error.toString().toLowerCase();
  if (error is TimeoutException || text.contains('timeout')) {
    return Friendly.slow;
  }
  if ([
    'failed to fetch',
    'socket',
    'network',
    'connection',
    'clientexception',
    'offline',
  ].any(text.contains)) {
    return Friendly.connection;
  }
  return fallback;
}
