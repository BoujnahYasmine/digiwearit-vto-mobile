import 'package:digiwearit2/experience_failure.dart';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/outfit_selection.dart';
import 'package:digiwearit2/try_on_session.dart';
import 'package:digiwearit2/welcome_screen.dart';
import 'package:digiwearit2/mirror/mirror_content.dart';
import 'package:digiwearit2/mirror/mirror_content_service.dart';
import 'package:digiwearit2/mirror/mirror_generation_service.dart';
import 'package:digiwearit2/mirror/mirror_session_service.dart';
import 'package:digiwearit2/mirror/mirror_tryon_controller.dart';
import 'package:digiwearit2/mirror/mirror_setup_screen.dart';
import 'package:digiwearit2/mirror/mirror_result_screen.dart';
import 'fixtures.dart';

class FakeSession implements MirrorSessionGateway {
  FakeSession({this.authenticated = true});
  bool authenticated;
  @override
  bool get isAuthenticated => authenticated;
  @override
  Future<MirrorSession?> restore({bool silent = true}) async => authenticated
      ? const MirrorSession(enterpriseId: 'e1', enterpriseName: 'Acme')
      : null;
  @override
  Future<MirrorSession?> refresh() async => authenticated
      ? const MirrorSession(enterpriseId: 'e1', enterpriseName: 'Acme')
      : null;
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
    return 'req-${_seq.toString().padLeft(10, '0')}';
  }

  @override
  Future<MirrorGenerationResult> generate({
    required String outfitId,
    required Uint8List customerImage,
    bool allowMakeup = false,
    required String requestId,
  }) async {
    requests.add(requestId);
    if (handler != null) return handler!();
    return MirrorGenerationResult(requestId: requestId, image: customerImage);
  }
}

Future<Uint8List> watermark(Uint8List image) async => image;

MirrorContent acmeContent() => MirrorContent(
  enterpriseId: 'acme',
  enterpriseName: 'Acme',
  catalogues: [
    MirrorCatalogue(
      id: 'c1',
      name: 'Collection Acme',
      outfits: [MirrorOutfit(id: 'o1', name: 'Tenue Acme', imageUrl: 'x')],
    ),
  ],
);

MirrorTryOnController controllerWith(MirrorSessionGateway session) =>
    MirrorTryOnController(
      sessionService: session,
      contentService: FakeContent(acmeContent()),
      generationService: FakeGeneration(),
      watermark: (image) async => image,
    );

OutfitSelection selection() => OutfitSelection(
  outfit: model('a', 'Caftan Royal'),
  gender: 'femme',
  english: false,
  style: 'Marocain',
);

Future<void> toResult(
  MirrorTryOnController controller, {
  Uint8List? bytes,
}) async {
  await controller.loadContent();
  controller.selectCatalogue('c1');
  controller.selectOutfit('o1');
  await controller.confirmPhoto(bytes ?? Uint8List.fromList([1, 2, 3]));
}

void main() {
  setUp(() {
    TryOnSession.current.reset();
  });
  tearDown(() {
    TryOnSession.current.reset();
  });

  group('welcome screen two-mode navigation', () {
    testWidgets('public button opens the public try-on on a clean session', (
      tester,
    ) async {
      final session = TryOnSession.current;
      session.confirm(selection(), Uint8List(1));
      session.setPayment(PaymentStatus.paid);
      expect(session.capturedPhoto, isNotNull);
      await tester.pumpWidget(
        app(
          const WelcomeScreen(),
          routes: {
            '/universe': (_) => const Scaffold(body: Text('Public universe')),
            '/mirror': (_) => const Scaffold(body: Text('Partner space')),
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('personal-start')));
      await tester.pumpAndSettle();
      expect(find.text('Public universe'), findsOneWidget);
      expect(session.capturedPhoto, isNull);
      expect(session.outfit, isNull);
      expect(session.payment, PaymentStatus.pending);
    });

    testWidgets('partner button opens the device flow, with no mirror entry', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          const WelcomeScreen(),
          routes: {
            '/universe': (_) => const Scaffold(body: Text('U')),
            '/mirror': (_) => const Scaffold(body: Text('Partner space')),
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Espace miroir'), findsNothing);
      expect(find.byKey(const ValueKey('mirror-start')), findsNothing);
      expect(find.text('Commencer l’essayage'), findsOneWidget);
      expect(find.text('Espace partenaire'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('partner-start')));
      await tester.pumpAndSettle();
      expect(find.text('Partner space'), findsOneWidget);
    });

    testWidgets(
      'switching to partner mode clears an in-flight public session',
      (tester) async {
        final session = TryOnSession.current;
        session.confirm(selection(), Uint8List(1));
        session.setPayment(PaymentStatus.processing);
        await tester.pumpWidget(
          app(
            const WelcomeScreen(),
            routes: {
              '/universe': (_) => const Scaffold(body: Text('U')),
              '/mirror': (_) => const Scaffold(body: Text('Partner space')),
            },
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('partner-start')));
        await tester.pumpAndSettle();
        expect(session.capturedPhoto, isNull);
        expect(session.outfit, isNull);
        expect(session.payment, PaymentStatus.pending);
        expect(find.text('Partner space'), findsOneWidget);
      },
    );

    testWidgets('switching back to public mode starts a clean try-on', (
      tester,
    ) async {
      final session = TryOnSession.current;
      session.confirm(selection(), Uint8List(1));
      session.setPayment(PaymentStatus.paid);
      await tester.pumpWidget(
        app(
          const WelcomeScreen(),
          routes: {
            '/universe': (_) => const Scaffold(body: Text('U')),
            '/mirror': (_) => const Scaffold(body: Text('Partner space')),
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('personal-start')));
      await tester.pumpAndSettle();
      expect(find.text('U'), findsOneWidget);
      expect(session.capturedPhoto, isNull);
      expect(session.payment, PaymentStatus.pending);
    });
  });

  group('partner device activation', () {
    testWidgets('startup failure stays on activation and allows retry', (
      tester,
    ) async {
      final controller = controllerWith(FakeSession(authenticated: false));
      await tester.pumpWidget(
        MaterialApp(
          home: MirrorSetupScreen(
            controller: controller,
            ensureReady: () async => throw StateError('offline'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.text('Connexion impossible. Veuillez réessayer.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('mirror-token-field')))
            .enabled,
        isTrue,
      );
    });

    testWidgets(
      'content load failure after activation is visible and clears the token',
      (tester) async {
        final session = FakeSession(authenticated: false);
        final controller = MirrorTryOnController(
          sessionService: session,
          contentService: FailingMirrorContent(),
          generationService: FakeGeneration(),
          watermark: watermark,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: MirrorSetupScreen(
              controller: controller,
              ensureReady: () async {},
              authenticator: (_) async {
                session.authenticated = true;
                return const MirrorSession(
                  enterpriseId: 'acme',
                  enterpriseName: 'Acme',
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('mirror-token-field')),
          'DW-test-token',
        );
        await tester.tap(find.byKey(const ValueKey('mirror-connect')));
        await tester.pumpAndSettle();
        expect(controller.contentError, isNotNull);
        expect(find.text(controller.contentError!), findsOneWidget);
        expect(
          tester
              .widget<TextField>(
                find.byKey(const ValueKey('mirror-token-field')),
              )
              .controller!
              .text,
          isEmpty,
        );
      },
    );

    test(
      'an existing valid device session is restored without a new code',
      () async {
        final session = FallbackSession();
        final controller = controllerWith(session);
        final ok = await controller.loadContent();
        expect(ok, isTrue);
        expect(controller.state, MirrorTryOnState.selectingCatalogue);
        expect(controller.content?.enterpriseName, 'Acme');
        expect(controller.isAuthenticated, isTrue);
      },
    );

    testWidgets('a new device activates with a valid DW code', (tester) async {
      final session = FakeSession(authenticated: false);
      final controller = controllerWith(session);
      await tester.pumpWidget(
        MaterialApp(
          home: MirrorSetupScreen(
            controller: controller,
            ensureReady: () async {},
            authenticator: (token) async {
              expect(token, 'DW-acme-valid-token-123456');
              session.authenticated = true;
              return const MirrorSession(
                enterpriseId: 'acme',
                enterpriseName: 'Acme',
              );
            },
          ),
          routes: {
            '/mirror/universe': (_) =>
                const Scaffold(body: Text('Choose model')),
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('mirror-token-field')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('mirror-token-field')),
        'DW-acme-valid-token-123456',
      );
      await tester.tap(find.byKey(const ValueKey('mirror-connect')));
      await tester.pumpAndSettle();
      expect(find.text('Choose model'), findsOneWidget);
      expect(
        find.text(
          'Entrez le code d’activation fourni par Digiwearit pour activer cet appareil.',
        ),
        findsNothing,
      );
    });

    testWidgets('an invalid activation code is rejected', (tester) async {
      final controller = controllerWith(FakeSession(authenticated: false));
      await tester.pumpWidget(
        MaterialApp(
          home: MirrorSetupScreen(
            controller: controller,
            ensureReady: () async {},
            authenticator: (_) async {
              throw MirrorSessionException('INVALID_MIRROR_TOKEN');
            },
          ),
          routes: {
            '/mirror/catalogues': (_) =>
                const Scaffold(body: Text('Catalogues')),
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('mirror-token-field')),
        'not-a-dw-code',
      );
      await tester.tap(find.byKey(const ValueKey('mirror-connect')));
      await tester.pumpAndSettle();
      expect(find.text('Code d’activation invalide.'), findsOneWidget);
      expect(find.text('Catalogues'), findsNothing);
    });
  });

  group('partner content and generation', () {
    test(
      'partner content is only the authenticated enterprise content',
      () async {
        final controller = controllerWith(FakeSession());
        await controller.loadContent();
        expect(controller.content?.enterpriseId, 'acme');
        expect(controller.content?.catalogues, hasLength(1));
        expect(controller.content!.catalogues.single.name, 'Collection Acme');
      },
    );

    test('partner generation ends on result with no payment state', () async {
      final controller = controllerWith(FakeSession());
      await toResult(controller);
      expect(controller.state, MirrorTryOnState.result);
      expect(controller.generatedImage, isNotNull);
      expect(controller.brandedGeneratedImage, isNotNull);
    });

    test(
      'enterprise quota errors are surfaced as partner quota messages',
      () async {
        final generation = FakeGeneration()
          ..handler = () =>
              throw MirrorGenerationException('AI_QUOTA_EXCEEDED');
        final controller = MirrorTryOnController(
          sessionService: FakeSession(),
          contentService: FakeContent(acmeContent()),
          generationService: generation,
          watermark: watermark,
        );
        await controller.loadContent();
        controller.selectCatalogue('c1');
        controller.selectOutfit('o1');
        await controller.confirmPhoto(Uint8List(1));
        expect(controller.error?.kind, MirrorErrorKind.quota);
        expect(
          controller.error?.message,
          Friendly.quota,
        );
      },
    );

    test(
      'duplicate confirmation produces a single generation request',
      () async {
        final generation = FakeGeneration();
        final gate = Completer<MirrorGenerationResult>();
        generation.handler = () => gate.future;
        final controller = MirrorTryOnController(
          sessionService: FakeSession(),
          contentService: FakeContent(acmeContent()),
          generationService: generation,
          watermark: watermark,
        );
        await controller.loadContent();
        controller.selectCatalogue('c1');
        controller.selectOutfit('o1');
        final first = controller.confirmPhoto(Uint8List(1));
        await pumpEventQueue();
        final second = controller.confirmPhoto(Uint8List(1));
        await pumpEventQueue();
        expect(generation.requests, hasLength(1));
        gate.complete(
          MirrorGenerationResult(
            requestId: 'req-0000000001',
            image: Uint8List(2),
          ),
        );
        await Future.wait([first, second]);
        expect(generation.requests, hasLength(1));
        expect(controller.state, MirrorTryOnState.result);
      },
    );

    testWidgets('mirror result screen shows no payment UI', (tester) async {
      final controller = controllerWith(FakeSession());
      final validPng = await photo(tester);
      await toResult(controller, bytes: validPng);
      await tester.pumpWidget(
        MaterialApp(home: MirrorResultScreen(controller: controller)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Votre essayage est prêt ✨'), findsOneWidget);
      expect(find.textContaining('Payer'), findsNothing);
      expect(find.text('29 DH'), findsNothing);
      expect(find.textContaining('paiement'), findsNothing);
      expect(find.byKey(const ValueKey('demo-pay')), findsNothing);
    });
  });

  group('public reveal still requires payment', () {
    test(
      'a completed public try-on is only revealed after the demo payment',
      () async {
        final session = TryOnSession(
          generator: (_) async => [
            Uint8List.fromList([1, 2, 3]),
          ],
        );
        session.confirm(selection(), Uint8List(4));
        await session.generate();
        expect(session.status, TryOnStatus.completed);
        expect(session.canReveal, isFalse);
        session.setPayment(PaymentStatus.failed);
        expect(session.canReveal, isFalse);
        session.setPayment(PaymentStatus.paid);
        expect(session.canReveal, isTrue);
        session.dispose();
      },
    );
  });

  group('customer privacy and next customer', () {
    test(
      'finishing a partner try-on clears the customer and keeps the device',
      () async {
        final controller = controllerWith(FakeSession());
        await toResult(controller);
        expect(controller.state, MirrorTryOnState.result);
        controller.returnHome();
        expect(controller.state, MirrorTryOnState.idle);
        expect(controller.selectedCatalogueId, isNull);
        expect(controller.selectedOutfitId, isNull);
        expect(controller.capturedPhoto, isNull);
        expect(controller.generatedImage, isNull);
        expect(controller.brandedGeneratedImage, isNull);
        expect(
          controller.isAuthenticated,
          isTrue,
          reason: 'device activation must survive a customer reset',
        );
        expect(
          controller.content,
          isNotNull,
          reason: 'enterprise content stays cached for the next customer',
        );
      },
    );

    test('a second customer starts from an empty try-on state', () async {
      final controller = controllerWith(FakeSession());
      await toResult(controller);
      controller.returnHome();
      await controller.loadContent();
      expect(controller.state, MirrorTryOnState.selectingCatalogue);
      expect(controller.capturedPhoto, isNull);
      expect(controller.generatedImage, isNull);
      controller.selectCatalogue('c1');
      controller.selectOutfit('o1');
      await controller.confirmPhoto(Uint8List(9));
      expect(controller.capturedPhoto, isNotNull);
      expect(controller.requestId, isNotNull);
    });
  });
}

class FallbackSession implements MirrorSessionGateway {
  bool authenticated = false;
  bool restored = false;
  int refreshCalls = 0;
  @override
  bool get isAuthenticated => authenticated;
  @override
  Future<MirrorSession?> restore({bool silent = true}) async {
    restored = true;
    authenticated = true;
    return const MirrorSession(enterpriseId: 'e1', enterpriseName: 'Acme');
  }

  @override
  Future<MirrorSession?> refresh() async {
    refreshCalls++;
    return authenticated
        ? const MirrorSession(enterpriseId: 'e1', enterpriseName: 'Acme')
        : null;
  }
}

class FailingMirrorContent implements MirrorContentGateway {
  @override
  Future<MirrorContent> load() async =>
      throw MirrorSessionException('SUBSCRIPTION_EXPIRED');
}
