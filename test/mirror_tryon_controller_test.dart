import 'package:digiwearit2/experience_failure.dart';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/mirror/mirror_content.dart';
import 'package:digiwearit2/mirror/mirror_content_service.dart';
import 'package:digiwearit2/mirror/mirror_generation_service.dart';
import 'package:digiwearit2/mirror/mirror_session_service.dart';
import 'package:digiwearit2/mirror/mirror_tryon_controller.dart';

class FakeSession implements MirrorSessionGateway {
  bool authenticated = true;
  int refreshCalls = 0;

  @override
  bool get isAuthenticated => authenticated;

  @override
  Future<MirrorSession?> restore({bool silent = true}) async => authenticated
      ? const MirrorSession(enterpriseId: 'e1', enterpriseName: 'E')
      : null;

  @override
  Future<MirrorSession?> refresh() async {
    refreshCalls++;
    return authenticated
        ? const MirrorSession(enterpriseId: 'e1', enterpriseName: 'E')
        : null;
  }
}

class FakeContent implements MirrorContentGateway {
  FakeContent(this.content);
  MirrorContent content;

  @override
  Future<MirrorContent> load() async => content;
}

class FakeGeneration implements MirrorGenerationGateway {
  int _seq = 0;
  final List<String> requests = [];

  Future<MirrorGenerationResult> Function()? handler;

  @override
  String newRequestId() {
    _seq++;
    return 'request-${_seq.toString().padLeft(10, '0')}';
  }

  @override
  Future<MirrorGenerationResult> generate({
    required String outfitId,
    required Uint8List customerImage,
    bool allowMakeup = false,
    required String requestId,
  }) async {
    requests.add(requestId);
    if (handler != null) {
      return handler!.call();
    }
    return MirrorGenerationResult(requestId: requestId, image: customerImage);
  }
}

Uint8List bytes() => Uint8List.fromList(List<int>.filled(64, 7));

MirrorContent contentWithOne(String catalogueId, String outfitId) =>
    MirrorContent(
      enterpriseId: 'e1',
      enterpriseName: 'Espace test',
      catalogues: [
        MirrorCatalogue(
          id: catalogueId,
          name: 'Cat 1',
          outfits: [MirrorOutfit(id: outfitId, name: 'Tenue 1', imageUrl: 'x')],
        ),
      ],
    );

Future<Uint8List> watermark(Uint8List image) async =>
    Uint8List.fromList([0x77, ...image]);

Future<void> settle() => pumpEventQueue();

Uint8List generated = Uint8List.fromList([1, 2, 3]);

void main() {
  late FakeSession session;
  late FakeContent content;
  late FakeGeneration generation;
  late MirrorTryOnController controller;

  setUp(() {
    session = FakeSession();
    content = FakeContent(contentWithOne('c1', 'o1'));
    generation = FakeGeneration();
    controller = MirrorTryOnController(
      sessionService: session,
      contentService: content,
      generationService: generation,
      watermark: watermark,
    );
  });

  group('content loading', () {
    test('loads catalogue and moves to selectingCatalogue', () async {
      expect(controller.state, MirrorTryOnState.idle);
      final ok = await controller.loadContent();
      expect(ok, isTrue);
      expect(controller.state, MirrorTryOnState.selectingCatalogue);
      expect(controller.content?.catalogues, hasLength(1));
      expect(controller.isAuthenticated, isTrue);
    });

    test('silently restores a cached session when not authenticated', () async {
      session.authenticated = false;
      session = FakeSession()..authenticated = false;
      controller = MirrorTryOnController(
        sessionService: session,
        contentService: content,
        generationService: generation,
        watermark: watermark,
      );
      final ok = await controller.loadContent();
      expect(ok, isFalse);
      expect(controller.state, MirrorTryOnState.idle);
      expect(controller.contentError, isNotNull);
    });
  });

  group('generation', () {
    test('happy path ends on result with branded image', () async {
      final img = generated;
      final completer = Completer<MirrorGenerationResult>();
      generation.handler = () => completer.future;
      await controller.loadContent();
      controller.selectCatalogue('c1');
      controller.selectOutfit('o1');
      expect(controller.state, MirrorTryOnState.camera);
      final future = controller.confirmPhoto(img);
      await settle();
      expect(controller.state, MirrorTryOnState.generating);
      completer.complete(
        MirrorGenerationResult(requestId: 'request-0000000001', image: img),
      );
      await future;
      expect(controller.state, MirrorTryOnState.result);
      expect(controller.generatedImage, img);
      expect(controller.brandedGeneratedImage, await watermark(img));
      expect(generation.requests, hasLength(1));
    });

    test('duplicate confirmPhoto taps produce a single generation', () async {
      final gate = Completer<MirrorGenerationResult>();
      generation.handler = () => gate.future;
      await controller.loadContent();
      controller.selectCatalogue('c1');
      controller.selectOutfit('o1');
      final first = controller.confirmPhoto(bytes());
      await settle();
      final second = controller.confirmPhoto(bytes());
      await settle();
      expect(generation.requests, hasLength(1));
      expect(controller.state, MirrorTryOnState.generating);
      gate.complete(MirrorGenerationResult(requestId: 'r', image: generated));
      await Future.wait([first, second]);
      expect(controller.state, MirrorTryOnState.result);
      expect(generation.requests, hasLength(1));
    });

    test('keeps the same requestId on an uncertain network failure', () async {
      var calls = 0;
      generation.handler = () {
        calls++;
        if (calls == 1) throw MirrorGenerationException('NETWORK_ERROR');
        return Future.value(
          MirrorGenerationResult(
            requestId: 'request-0000000001',
            image: generated,
          ),
        );
      };
      await controller.loadContent();
      controller.selectCatalogue('c1');
      controller.selectOutfit('o1');
      await controller.confirmPhoto(bytes());
      expect(controller.state, MirrorTryOnState.error);
      expect(controller.error?.retryable, isTrue);
      expect(controller.error?.uncertain, isTrue);
      expect(controller.error?.message, Friendly.connection);
      await controller.retryGeneration();
      expect(controller.state, MirrorTryOnState.result);
      expect(generation.requests, hasLength(2));
      expect(
        generation.requests[0],
        generation.requests[1],
        reason: 'uncertain outcomes must reuse the requestId',
      );
    });

    test('uses a fresh requestId after a confirmed provider failure', () async {
      var calls = 0;
      generation.handler = () {
        calls++;
        if (calls == 1) throw MirrorGenerationException('AI_PROVIDER_ERROR');
        return Future.value(
          MirrorGenerationResult(
            requestId: 'request-0000000001',
            image: generated,
          ),
        );
      };
      await controller.loadContent();
      controller.selectCatalogue('c1');
      controller.selectOutfit('o1');
      await controller.confirmPhoto(bytes());
      expect(controller.error?.message, Friendly.generation);
      await controller.retryGeneration();
      expect(controller.state, MirrorTryOnState.result);
      expect(generation.requests, hasLength(2));
      expect(
        generation.requests[0],
        isNot(generation.requests[1]),
        reason: 'confirmed final failures must use a new requestId',
      );
    });

    test(
      'GENERATION_ALREADY_COMPLETED maps to a retryable provider error',
      () async {
        generation.handler = () =>
            throw MirrorGenerationException('GENERATION_ALREADY_COMPLETED');
        await controller.loadContent();
        controller.selectCatalogue('c1');
        controller.selectOutfit('o1');
        await controller.confirmPhoto(bytes());
        expect(controller.state, MirrorTryOnState.error);
        expect(controller.error?.retryable, isTrue);
        expect(controller.error?.code, 'GENERATION_ALREADY_COMPLETED');
      },
    );

    test('AI_QUOTA_EXCEEDED maps to quota message and backToOutfits', () async {
      generation.handler = () =>
          throw MirrorGenerationException('AI_QUOTA_EXCEEDED');
      await controller.loadContent();
      controller.selectCatalogue('c1');
      controller.selectOutfit('o1');
      await controller.confirmPhoto(bytes());
      expect(controller.error?.kind, MirrorErrorKind.quota);
      expect(controller.error?.message, Friendly.quota);
      expect(controller.error?.backToOutfits, isTrue);
      expect(controller.error?.retryable, isFalse);
    });

    test('OUTFIT_NOT_AVAILABLE maps to a backToOutfits error', () async {
      generation.handler = () =>
          throw MirrorGenerationException('OUTFIT_NOT_AVAILABLE');
      await controller.loadContent();
      controller.selectCatalogue('c1');
      controller.selectOutfit('o1');
      await controller.confirmPhoto(bytes());
      expect(controller.error?.message, Friendly.outfitUnavailable);
      expect(controller.error?.backToOutfits, isTrue);
    });

    test(
      'session expiry refreshes once and retries with the same requestId',
      () async {
        var calls = 0;
        generation.handler = () {
          calls++;
          if (calls == 1) {
            throw MirrorGenerationException('MIRROR_SESSION_REQUIRED');
          }
          return Future.value(
            MirrorGenerationResult(
              requestId: 'request-0000000001',
              image: generated,
            ),
          );
        };
        await controller.loadContent();
        controller.selectCatalogue('c1');
        controller.selectOutfit('o1');
        await controller.confirmPhoto(bytes());
        expect(controller.state, MirrorTryOnState.result);
        expect(generation.requests, hasLength(2));
        expect(generation.requests[0], generation.requests[1]);
        expect(session.refreshCalls, 1);
      },
    );
  });

  group('privacy and reset', () {
    Future<void> toResult() async {
      await controller.loadContent();
      controller.selectCatalogue('c1');
      controller.selectOutfit('o1');
      await controller.confirmPhoto(bytes());
    }

    test('returnHome keeps mirror authentication and content', () async {
      content.content = contentWithOne('c1', 'o1');
      await toResult();
      expect(controller.state, MirrorTryOnState.result);
      controller.returnHome();
      expect(controller.state, MirrorTryOnState.idle);
      expect(controller.selectedOutfitId, isNull);
      expect(controller.capturedPhoto, isNull);
      expect(controller.generatedImage, isNull);
      expect(controller.brandedGeneratedImage, isNull);
      expect(
        controller.isAuthenticated,
        isTrue,
        reason: 'mirror auth must survive customer resets',
      );
      expect(
        controller.content,
        isNotNull,
        reason: 'enterprise content stays cached for the next customer',
      );
    });

    test(
      'another outfit reuses original photo with a new request until done',
      () async {
        await toResult();
        final original = controller.capturedPhoto;
        final firstRequest = controller.requestId;
        controller.tryAnotherOutfit();
        expect(controller.state, MirrorTryOnState.selectingCatalogue);
        expect(controller.capturedPhoto, same(original));
        expect(controller.generatedImage, isNull);
        expect(controller.brandedGeneratedImage, isNull);
        content.content = contentWithOne('c2', 'o2');
        await controller.loadContent(forceRefresh: true);
        controller.selectCatalogue('c2');
        controller.selectOutfit('o2');
        expect(controller.state, MirrorTryOnState.photoPreview);
        await controller.generate();
        expect(controller.state, MirrorTryOnState.result);
        expect(controller.generatedImage, same(original));
        expect(controller.requestId, isNot(firstRequest));
        controller.returnHome();
        expect(controller.capturedPhoto, isNull);
        controller.selectCatalogue('c2');
        controller.selectOutfit('o2');
        expect(controller.state, MirrorTryOnState.camera);
      },
    );
  });

  test('watermark failure falls back to the raw generated image', () async {
    controller = MirrorTryOnController(
      sessionService: session,
      contentService: content,
      generationService: generation,
      watermark: (image) async {
        throw StateError('boom');
      },
    );
    await controller.loadContent();
    controller.selectCatalogue('c1');
    controller.selectOutfit('o1');
    await controller.confirmPhoto(bytes());
    expect(controller.state, MirrorTryOnState.result);
    expect(controller.brandedGeneratedImage, controller.generatedImage);
  });
}
