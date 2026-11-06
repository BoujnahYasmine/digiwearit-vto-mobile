import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'mirror_backend.dart';
import 'mirror_access_state.dart';

/// Human-safe mirror authentication failures. Reasons are backend opaque
/// codes; token and session credentials are never carried here.
class MirrorSessionException implements Exception {
  MirrorSessionException(this.reason);
  final String reason;

  String get message => switch (reason) {
    'INVALID_MIRROR_TOKEN' => 'Code d’activation invalide.',
    'ENTERPRISE_NOT_ACTIVE' =>
      'Cette entreprise est en attente d’activation. Contactez Digiwearit.',
    'ENTERPRISE_SUSPENDED' =>
      'Cette entreprise est suspendue. Contactez Digiwearit.',
    'MIRROR_SUSPENDED' => 'Ce miroir est suspendu. Contactez Digiwearit.',
    'SUBSCRIPTION_EXPIRED' ||
    'SUBSCRIPTION_SUSPENDED' => 'L’abonnement de cet espace a expiré.',
    'AI_QUOTA_EXCEEDED' => 'Le quota d’essayages a été atteint.',
    'MIRROR_LIMIT_REACHED' =>
      'Tous les miroirs autorisés par l’abonnement sont déjà activés. Contactez Digiwearit.',
    _ => 'Impossible de connecter l’espace partenaire.',
  };

  bool get sessionExpired =>
      reason == 'MIRROR_SESSION_REQUIRED' ||
      reason == 'INVALID_MIRROR_TOKEN' ||
      reason == 'SESSION_EXPIRED';
}

/// The authenticated mirror identity. Holds only operational, non-secret
/// fields; the raw mirror token never stays in memory beyond authentication.
class MirrorSession {
  const MirrorSession({
    required this.enterpriseId,
    required this.enterpriseName,
    this.logoUrl,
    this.plan,
    this.remainingQuota,
  });
  final String enterpriseId;
  final String enterpriseName;
  final String? logoUrl;
  final String? plan;
  final int? remainingQuota;

  factory MirrorSession.fromAuth(Map<String, dynamic> data) {
    final enterprise = (data['enterprise'] as Map? ?? const {})
        .cast<String, dynamic>();
    final subscription = (data['subscription'] as Map? ?? const {})
        .cast<String, dynamic>();
    return MirrorSession(
      enterpriseId: enterprise['id'] as String? ?? '',
      enterpriseName: enterprise['name'] as String? ?? 'Espace partenaire',
      logoUrl: enterprise['logoUrl'] as String?,
      plan: subscription['plan'] as String?,
      remainingQuota: subscription['remainingQuota'] as int?,
    );
  }
}

/// Gateway used by the try-on controller; tests inject fakes.
abstract interface class MirrorSessionGateway {
  bool get isAuthenticated;
  Future<MirrorSession?> restore({bool silent});
  Future<MirrorSession?> refresh();
}

/// Owns the persisted Firebase mirror session; activation codes are not saved.
///
/// This is intentionally separate from the customer try-on controller:
/// mirror authentication must survive customer resets and completion.
class MirrorSessionService implements MirrorSessionGateway {
  MirrorSessionService({FlutterSecureStorage? storage, FirebaseAuth? auth})
    : _storage = storage ?? const FlutterSecureStorage(),
      _providedAuth = auth;

  static final MirrorSessionService instance = MirrorSessionService();
  static const String tokenKey = 'digiwearit_mirror_token';

  final FlutterSecureStorage _storage;
  final FirebaseAuth? _providedAuth;
  FirebaseAuth get _auth => _providedAuth ?? FirebaseAuth.instance;

  Future<void> _clearLegacyToken() async {
    try {
      await _storage.delete(key: tokenKey);
    } on Object {
      // Storage availability must not invalidate a persisted Firebase session.
    }
  }

  MirrorSession? _session;
  bool _authenticating = false;

  @override
  bool get isAuthenticated => _session != null && _auth.currentUser != null;
  MirrorSession? get session => isAuthenticated ? _session : null;

  /// Silently restores a previous mirror login. Returns null when nothing is
  /// stored or the stored credential is no longer valid.
  @override
  Future<MirrorSession?> restore({bool silent = true}) async {
    if (isAuthenticated) return _session;
    try {
      await MirrorBackend.ensureReady();
      // Firebase Auth persists its refresh credential, never the activation code.
      await _auth.authStateChanges().first;
      await _clearLegacyToken();
      final user = _auth.currentUser;
      if (user == null) return null;
      final claims = await user.getIdTokenResult();
      if (claims.claims?['role'] != 'mirror') return null;
      final result = await MirrorBackend.functions
          .httpsCallable('getMirrorContent')
          .call<Map<String, dynamic>>();
      _session = MirrorSession.fromAuth(result.data);
      return _session;
    } on Object {
      _session = null;
      return null;
    }
  }

  /// Exchanges the mirror token for a short-lived Firebase session.
  Future<MirrorSession> authenticate(
    String token, {
    bool persist = true,
    bool silent = false,
  }) async {
    if (_authenticating) {
      throw MirrorSessionException('SESSION_IN_PROGRESS');
    }
    MirrorAccessState.shared.reset();
    _authenticating = true;
    try {
      await MirrorBackend.ensureReady();
      final functions = MirrorBackend.functions;
      final result = await functions
          .httpsCallable('authenticateMirror')
          .call<Map<String, dynamic>>({'token': token.trim()});
      final sessionToken = result.data['sessionToken'];
      if (sessionToken is! String || sessionToken.isEmpty) {
        throw MirrorSessionException('INVALID_MIRROR_TOKEN');
      }
      await _auth.signInWithCustomToken(sessionToken);
      if (persist) {
        await _clearLegacyToken();
      }
      final session = MirrorSession.fromAuth(result.data);
      _session = session;
      return session;
    } on FirebaseFunctionsException catch (error) {
      final reason = error.details is Map
          ? (error.details as Map)['reason']?.toString()
          : error.message;
      throw MirrorSessionException(reason ?? 'UNKNOWN');
    } on MirrorSessionException {
      rethrow;
    } on Object {
      throw MirrorSessionException('UNKNOWN');
    } finally {
      _authenticating = false;
    }
  }

  /// Restores the persisted Firebase session without reusing an activation code.
  @override
  Future<MirrorSession?> refresh() async {
    if (isAuthenticated) return _session;
    return restore(silent: true);
  }

  Future<void> signOut() async {
    MirrorAccessState.shared.reset();
    _session = null;
    try {
      await _clearLegacyToken();
    } on Object {
      // Best effort: the in-memory session is cleared regardless.
    }
    try {
      await _auth.signOut();
    } on Object {
      // Ignore: nothing else keeps the mirror session alive.
    }
  }
}
