import '../experience_failure.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../digiwearit_watermark.dart';
import 'mirror_content.dart';
import 'mirror_content_service.dart';
import 'mirror_generation_service.dart';
import 'mirror_session_service.dart';

/// Customer try-on flow states. Mirror authentication is kept separate.
enum MirrorTryOnState {
  idle,
  selectingCatalogue,
  selectingOutfit,
  camera,
  photoPreview,
  generating,
  result,
  error,
}

enum MirrorErrorKind {
  quota,
  suspended,
  subscription,
  outfitUnavailable,
  provider,
  network,
  session,
  unknown,
}

/// Customer-facing error. `retryable` allows a new attempt from the error
/// screen; `uncertain` means the earlier request may already have been
/// processed server-side, so the same requestId is reused on retry.
class MirrorTryOnError {
  const MirrorTryOnError({
    required this.kind,
    required this.message,
    this.code,
    this.retryable = false,
    this.uncertain = false,
    this.backToOutfits = false,
  });
  final MirrorErrorKind kind;
  final String message;
  final String? code;
  final bool retryable;
  final bool uncertain;
  final bool backToOutfits;

  factory MirrorTryOnError.fromGeneration(MirrorGenerationException error) {
    final code = error.code;
    switch (code) {
      case 'AI_QUOTA_EXCEEDED':
        return const MirrorTryOnError(
          kind: MirrorErrorKind.quota,
          message: Friendly.quota,
          code: 'AI_QUOTA_EXCEEDED',
          backToOutfits: true,
        );
      case 'ENTERPRISE_SUSPENDED':
      case 'ENTERPRISE_NOT_ACTIVE':
      case 'MIRROR_SUSPENDED':
        return const MirrorTryOnError(
          kind: MirrorErrorKind.suspended,
          message: Friendly.servicePaused,
          code: 'ENTERPRISE_SUSPENDED',
        );
      case 'SUBSCRIPTION_EXPIRED':
      case 'SUBSCRIPTION_SUSPENDED':
        return const MirrorTryOnError(
          kind: MirrorErrorKind.subscription,
          message: Friendly.servicePaused,
          code: 'SUBSCRIPTION_EXPIRED',
        );
      case 'OUTFIT_NOT_AVAILABLE':
      case 'INVALID_OUTFIT':
        return const MirrorTryOnError(
          kind: MirrorErrorKind.outfitUnavailable,
          message: Friendly.outfitUnavailable,
          code: 'OUTFIT_NOT_AVAILABLE',
          backToOutfits: true,
        );
      case 'MIRROR_SESSION_REQUIRED':
      case 'SESSION_EXPIRED':
        return const MirrorTryOnError(
          kind: MirrorErrorKind.session,
          message: Friendly.mirrorReconnect,
          code: 'MIRROR_SESSION_REQUIRED',
          retryable: true,
        );
      case 'GENERATION_ALREADY_COMPLETED':
        // The request completed server-side but this device never received
        // the image bytes. A brand-new request is required.
        return const MirrorTryOnError(
          kind: MirrorErrorKind.provider,
          message: Friendly.generation,
          code: 'GENERATION_ALREADY_COMPLETED',
          retryable: true,
        );
      case 'AI_PROVIDER_ERROR':
      case 'AI_PROVIDER_UNAVAILABLE':
      case 'AI_REFERENCE_UNAVAILABLE':
        return const MirrorTryOnError(
          kind: MirrorErrorKind.provider,
          message: Friendly.generation,
          code: 'AI_PROVIDER_ERROR',
          retryable: true,
        );
      case 'NETWORK_ERROR':
      case 'DEADLINE_EXCEEDED':
      case null:
        return const MirrorTryOnError(
          kind: MirrorErrorKind.network,
          message: Friendly.connection,
          code: 'NETWORK_ERROR',
          retryable: true,
          uncertain: true,
        );
      default:
        return const MirrorTryOnError(
          kind: MirrorErrorKind.unknown,
          message: Friendly.generation,
          retryable: true,
          uncertain: true,
        );
    }
  }
}

/// Drives the authenticated mirror try-on flow: catalogue selection, outfit
/// selection, camera confirmation, AI generation (with idempotent request ids
/// and silent session refresh), result and reset.
class MirrorTryOnController extends ChangeNotifier {
  MirrorTryOnController({
    MirrorSessionGateway? sessionService,
    MirrorContentGateway? contentService,
    MirrorGenerationGateway? generationService,
    Future<Uint8List> Function(Uint8List)? watermark,
  }) : _sessionService = sessionService ?? MirrorSessionService.instance,
       _contentService = contentService ?? MirrorContentService(),
       _generationService = generationService ?? MirrorGenerationService(),
       _watermark = watermark ?? DigiwearitWatermark().apply;

  static final MirrorTryOnController current = MirrorTryOnController();

  final MirrorSessionGateway _sessionService;
  final MirrorContentGateway _contentService;
  final MirrorGenerationGateway _generationService;
  final Future<Uint8List> Function(Uint8List) _watermark;

  MirrorTryOnState state = MirrorTryOnState.idle;
  bool loadingContent = false;
  String? contentError;

  MirrorContent? _content;
  String? _gender;
  bool _allowMakeup = false;
  bool get isFemaleJourney => _gender == 'femme' || _gender == 'female';
  bool get allowMakeup => isFemaleJourney && _allowMakeup;
  void setAllowMakeup(bool value) {
    _allowMakeup = isFemaleJourney && value;
    notifyListeners();
  }

  void setGender(String gender) {
    if (_gender == gender) return;
    _gender = gender;
    _allowMakeup = false;
    _selectedCatalogueId = null;
    _selectedOutfitId = null;
  }

  List<MirrorCatalogue> get visibleCatalogues =>
      (_content?.catalogues ?? const <MirrorCatalogue>[])
          .map(
            (catalogue) => MirrorCatalogue(
              id: catalogue.id,
              name: catalogue.name,
              imageUrl: catalogue.imageUrl,
              gender: catalogue.gender,
              outfits: catalogue.outfits
                  .where((outfit) => outfit.matchesGender(_gender))
                  .toList(),
            ),
          )
          .where((catalogue) => catalogue.outfits.isNotEmpty)
          .toList();

  String? _selectedCatalogueId;
  String? _selectedOutfitId;
  Uint8List? _capturedPhoto;
  Uint8List? _generatedImage;
  Uint8List? _brandedGeneratedImage;
  String? _requestId;
  MirrorTryOnError? _error;
  bool _generationInFlight = false;

  MirrorContent? get content => _content;
  String? get selectedCatalogueId => _selectedCatalogueId;
  String? get selectedOutfitId => _selectedOutfitId;
  Uint8List? get capturedPhoto => _capturedPhoto;
  Uint8List? get generatedImage => _generatedImage;
  Uint8List? get brandedGeneratedImage => _brandedGeneratedImage;
  String? get requestId => _requestId;
  MirrorTryOnError? get error => _error;

  MirrorCatalogue? get selectedCatalogue {
    final id = _selectedCatalogueId;
    if (id == null) return null;
    for (final catalogue in visibleCatalogues) {
      if (catalogue.id == id) return catalogue;
    }
    return null;
  }

  MirrorOutfit? get selectedOutfit {
    final id = _selectedOutfitId;
    if (id == null) return null;
    for (final outfit in selectedCatalogue?.outfits ?? const <MirrorOutfit>[]) {
      if (outfit.id == id) return outfit;
    }
    return null;
  }

  bool get isAuthenticated => _sessionService.isAuthenticated;

  /// Loads the authenticated enterprise content and moves to catalogue
  /// selection. Silent session restore is attempted first.
  Future<bool> loadContent({bool forceRefresh = false}) async {
    loadingContent = true;
    contentError = null;
    notifyListeners();
    try {
      if (!_sessionService.isAuthenticated) {
        final restored = await _sessionService.restore(silent: true);
        if (restored == null) {
          state = MirrorTryOnState.idle;
          contentError = Friendly.mirrorReconnect;
          return false;
        }
      }
      if (!forceRefresh && _content != null) {
        state = MirrorTryOnState.selectingCatalogue;
        return true;
      }
      final content = await _contentService.load();
      _content = content;
      state = MirrorTryOnState.selectingCatalogue;
      return true;
    } catch (error) {
      contentError = _sessionMessage(error);
      state = MirrorTryOnState.idle;
      return false;
    } finally {
      loadingContent = false;
      notifyListeners();
    }
  }

  void selectCatalogue(String catalogueId) {
    if (_selectedCatalogueId == catalogueId) return;
    _selectedCatalogueId = catalogueId;
    _selectedOutfitId = null;
    state = MirrorTryOnState.selectingOutfit;
    notifyListeners();
  }

  void selectOutfit(String outfitId) {
    _selectedOutfitId = outfitId;
    state = _capturedPhoto == null
        ? MirrorTryOnState.camera
        : MirrorTryOnState.photoPreview;
    notifyListeners();
  }

  /// Called when the customer confirms the captured photo.
  Future<void> confirmPhoto(Uint8List photo) async {
    if (_generationInFlight) return;
    _capturedPhoto = photo;
    state = MirrorTryOnState.photoPreview;
    notifyListeners();
    await generate();
  }

  Future<void> generate() async {
    if (_generationInFlight) return;
    final outfitId = _selectedOutfitId;
    final photo = _capturedPhoto;
    if (outfitId == null || photo == null) return;
    _generationInFlight = true;
    state = MirrorTryOnState.generating;
    _error = null;
    notifyListeners();
    try {
      await _runGeneration(outfitId: outfitId, photo: photo);
    } finally {
      _generationInFlight = false;
      notifyListeners();
    }
  }

  Future<void> _runGeneration({
    required String outfitId,
    required Uint8List photo,
    bool authRetried = false,
  }) async {
    if (authRetried == false) {
      if (!_sessionService.isAuthenticated) {
        final restored = await _sessionService.restore(silent: true);
        if (restored == null) {
          _fail(
            const MirrorTryOnError(
              kind: MirrorErrorKind.session,
              message: Friendly.mirrorReconnect,
              code: 'MIRROR_SESSION_REQUIRED',
              retryable: true,
            ),
          );
          return;
        }
      }
    }
    // A fresh generation only when the previous one is in no doubt; uncertain
    // network outcomes keep the same id so backend idempotency wins.
    if (_requestId == null || _previousWasFinal) {
      _requestId = _generationService.newRequestId();
    }
    final requestId = _requestId!;
    try {
      final result = await _generationService.generate(
        outfitId: outfitId,
        customerImage: photo,
        allowMakeup: allowMakeup,
        requestId: requestId,
      );
      _requestId = result.requestId;
      final branded = await _applyWatermark(result.image);
      _generatedImage = result.image;
      _brandedGeneratedImage = branded;
      _previousWasFinal = false;
      _error = null;
      state = MirrorTryOnState.result;
    } on MirrorGenerationException catch (failure) {
      if (failure.code == 'MIRROR_SESSION_REQUIRED' && !authRetried) {
        final refreshed = await _sessionService.refresh();
        if (refreshed != null) {
          await _runGeneration(
            outfitId: outfitId,
            photo: photo,
            authRetried: true,
          );
          return;
        }
      }
      _previousWasFinal = !_generationExceptionUncertain(failure);
      _fail(MirrorTryOnError.fromGeneration(failure));
    } on Object {
      _previousWasFinal = false;
      _fail(
        const MirrorTryOnError(
          kind: MirrorErrorKind.network,
          message: Friendly.connection,
          code: 'NETWORK_ERROR',
          retryable: true,
          uncertain: true,
        ),
      );
    }
  }

  bool _generationExceptionUncertain(MirrorGenerationException failure) =>
      failure.isUncertain;

  Future<Uint8List> _applyWatermark(Uint8List image) async {
    try {
      final branded = await _watermark(image);
      final logoUrl = _content?.logoUrl;
      if (logoUrl == null || logoUrl.isEmpty) return branded;
      try {
        final response = await http
            .get(Uri.parse(logoUrl))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200 || response.bodyBytes.length > 1048576) {
          return branded;
        }
        return await DigiwearitWatermark(
          logoLoader: (_) async => ByteData.sublistView(response.bodyBytes),
        ).apply(branded, topCenter: true);
      } catch (_) {
        return branded;
      }
    } on Object {
      // Watermarking must never discard a successful result.
      return image;
    }
  }

  void _fail(MirrorTryOnError failure) {
    _error = failure;
    state = MirrorTryOnState.error;
  }

  /// Retries generation after an error shown to the customer.
  Future<void> retryGeneration() async {
    final currentError = _error;
    if (currentError == null || !currentError.retryable) return;
    _error = null;
    await generate();
  }

  /// Customer tapped “Essayer une autre tenue”: clears customer state only.
  void tryAnotherOutfit() {
    _selectedCatalogueId = null;
    _selectedOutfitId = null;
    // Keep the original customer photo until the session is finished.
    _generatedImage = null;
    _brandedGeneratedImage = null;
    _error = null;
    _requestId = null;
    _previousWasFinal = false;
    state = MirrorTryOnState.selectingCatalogue;
    notifyListeners();
  }

  /// “Retour à l’accueil”: clears every temporary customer field while the
  /// mirror authentication, credential and enterprise content stay loaded.
  void returnHome() {
    _gender = null;
    _allowMakeup = false;
    _selectedCatalogueId = null;
    _selectedOutfitId = null;
    _capturedPhoto = null;
    _generatedImage = null;
    _brandedGeneratedImage = null;
    _error = null;
    _requestId = null;
    _previousWasFinal = false;
    state = MirrorTryOnState.idle;
    notifyListeners();
  }

  String _sessionMessage(Object error) {
    if (error is MirrorSessionException) return error.message;
    return Friendly.mirrorReconnect;
  }

  // Internals: whether the latest failed attempt had a confirmed outcome.
  bool _previousWasFinal = false;
}
