import 'package:cloud_functions/cloud_functions.dart';

import 'mirror_backend.dart';
import 'mirror_content.dart';
import 'mirror_session_service.dart';

/// Gateway used by the try-on controller; content is loaded through this
/// interface in tests as well.
abstract interface class MirrorContentGateway {
  Future<MirrorContent> load();
}

/// Loads the authenticated enterprise catalogue through the secure backend
/// content endpoint. It never queries enterpriseCatalogs/enterpriseOutfits
/// from Firestore directly.
class MirrorContentService implements MirrorContentGateway {
  MirrorContentService({FirebaseFunctions? functions})
    : _providedFunctions = functions;

  final FirebaseFunctions? _providedFunctions;
  FirebaseFunctions get _functions =>
      _providedFunctions ?? MirrorBackend.functions;

  @override
  Future<MirrorContent> load() async {
    final result = await _functions
        .httpsCallable('getMirrorContent')
        .call<Map<String, dynamic>>();
    final data = result.data;
    final enterprise = (data['enterprise'] as Map? ?? {})
        .cast<String, dynamic>();
    final subscription = (data['subscription'] as Map? ?? {})
        .cast<String, dynamic>();
    final catalogs = data['catalogs'] as List<dynamic>? ?? const [];
    return MirrorContent(
      enterpriseName: enterprise['name'] as String? ?? 'Espace partenaire',
      enterpriseId: enterprise['id'] as String? ?? '',
      logoUrl: enterprise['logoUrl'] as String?,
      plan: subscription['plan'] as String?,
      remainingQuota: subscription['remainingQuota'] as int?,
      catalogues: catalogs
          .map((raw) {
            final catalog = (raw as Map).cast<String, dynamic>();
            final outfits = catalog['outfits'] as List<dynamic>? ?? const [];
            return MirrorCatalogue(
              id: catalog['id'] as String? ?? '',
              name: catalog['name'] as String? ?? '',
              imageUrl: catalog['imageUrl'] as String?,
              gender: catalog['gender'] as String?,
              outfits: outfits
                  .whereType<Map>()
                  .map((rawOutfit) {
                    final outfit = rawOutfit.cast<String, dynamic>();
                    return MirrorOutfit(
                      id: outfit['id'] as String? ?? '',
                      gender: outfit['gender'] as String?,
                      name: outfit['name'] as String? ?? '',
                      imageUrl: outfit['imageUrl'] as String? ?? '',
                    );
                  })
                  .where((candidate) => candidate.id.isNotEmpty)
                  .toList(),
            );
          })
          .where((candidate) => candidate.id.isNotEmpty)
          .toList(),
    );
  }
}

/// Convenience: session scoped content fetch with refresh handling.
class MirrorContentLoader {
  MirrorContentLoader({
    MirrorSessionService? sessionService,
    MirrorContentService? contentService,
  }) : _sessionService = sessionService ?? MirrorSessionService.instance,
       _contentService = contentService ?? MirrorContentService();

  final MirrorSessionService _sessionService;
  final MirrorContentService _contentService;

  Future<MirrorContent> loadAuthenticated() async {
    if (!_sessionService.isAuthenticated) {
      final restored = await _sessionService.restore(silent: true);
      if (restored == null) {
        throw MirrorSessionException('MIRROR_SESSION_REQUIRED');
      }
    }
    return _contentService.load();
  }
}
