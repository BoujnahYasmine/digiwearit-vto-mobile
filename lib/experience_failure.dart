import 'dart:async';

class ExperienceFailure implements Exception {
  const ExperienceFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

String explainFailure(
  Object error, {
  String fallback = 'Le service est indisponible. Réessayez.',
}) {
  if (error is ExperienceFailure) return error.message;
  final text = error.toString().toLowerCase();
  if (error is TimeoutException || text.contains('timeout')) {
    return 'La connexion a pris trop de temps. Vérifiez votre connexion puis réessayez.';
  }
  if ([
    'failed to fetch',
    'socket',
    'network',
    'connection',
    'clientexception',
    'offline',
  ].any(text.contains)) {
    return 'Connexion interrompue. Vérifiez votre accès Internet puis réessayez.';
  }
  return fallback;
}
