import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/main.dart';
import 'package:digiwearit2/outfit_repository.dart';
import 'package:digiwearit2/outfit_selection.dart';
import 'package:digiwearit2/try_on_request.dart';
import 'package:digiwearit2/try_on_prompt.dart';
import 'package:digiwearit2/try_on_session.dart';
import 'package:digiwearit2/nano_banana_service.dart';
import 'package:digiwearit2/welcome_screen.dart';
import 'fixtures.dart';

void main() {
  OutfitSelection selection() => OutfitSelection(
    outfit: model('a', 'Caftan Royal'),
    gender: 'femme',
    english: false,
    style: 'Marocain',
  );
  test(
    'extracted default prompt is byte-for-byte equivalent to legacy prompt',
    () {
      final request = TryOnRequest(
        userPhotoBytes: Uint8List(1),
        outfit: selection().outfit,
        gender: 'femme',
        style: 'Marocain',
        category: 'Caftan',
      );
      expect(
        buildTryOnPrompt(request, hasBackground: false),
        File('test/legacy_prompt_golden.txt').readAsStringSync(),
      );
    },
  );
  test('outfit id and user bytes reach the generation function', () async {
    final outfit = Outfit.fromFirestore('regional', {
      'name': 'Ait Baamrane',
      'gender': 'femme',
      'category': 'Ait Baamrane',
      'active': true,
      'thumbnailUrl': 'display.jpg',
      'fullImageUrl': 'full.jpg',
      'promptImageUrl': 'reference.png',
      'imageUrls': ['old.jpg'],
    });
    final bytes = Uint8List.fromList([0x89, 0x50, 0x4e, 0x47]);
    Map<String, dynamic>? sent;
    final service = NanoBananaService(
      call: (data) async {
        sent = data;
        return {
          'images': [
            base64Encode([7, 8]),
          ],
        };
      },
    );
    final images = await service.generate(
      TryOnRequest(
        userPhotoBytes: bytes,
        outfit: outfit,
        gender: 'femme',
        style: 'Marocain',
        category: 'Ait Baamrane',
        preferredColorName: 'bleu',
      ),
    );
    expect(sent!['outfitId'], 'regional');
    expect(base64Decode(sent!['customerImage'] as String), bytes);
    expect(sent!['category'], 'Ait Baamrane');
    expect(sent!['preferredColorName'], 'bleu');
    expect(
      sent!.keys,
      isNot(contains('promptImageUrl')),
      reason: 'server reads the outfit',
    );
    expect(images.single, [7, 8]);
    expect(
      OutfitRepository.filter(
        [outfit],
        gender: 'femme',
        style: 'Marocain',
        category: 'Ait Baamrane',
      ),
      [outfit],
    );
    expect(
      OutfitRepository.filter([outfit], gender: 'homme', style: 'Marocain'),
      isEmpty,
    );
  });
  test('generation is deduplicated and payment is independent', () async {
    final pending = Completer<List<Uint8List>>();
    var calls = 0;
    final session = TryOnSession(
      generator: (request) {
        calls++;
        return pending.future;
      },
    );
    final bytes = Uint8List.fromList([1, 2, 3]);
    session.confirm(selection(), bytes);
    final a = session.generate(), b = session.generate();
    expect(identical(a, b), isTrue);
    session.setPayment(PaymentStatus.paid);
    expect(session.canReveal, isFalse);
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
    pending.complete([bytes]);
    await a;
    expect(session.canReveal, isTrue);
    await session.generate();
    expect(calls, 1);
    session.reset();
    expect(session.capturedPhoto, isNull);
    expect(session.results, isEmpty);
    expect(session.outfit, isNull);
    session.dispose();
  });
  test('reset discards results from a request still in flight', () async {
    final pending = Completer<List<Uint8List>>();
    final session = TryOnSession(generator: (_) => pending.future);
    session.confirm(selection(), Uint8List(1));
    final run = session.generate();
    await Future<void>.delayed(Duration.zero);
    session.reset();
    pending.complete([Uint8List(1)]);
    await run;
    expect(session.results, isEmpty);
    expect(session.status, TryOnStatus.idle);
    session.dispose();
  });
  test(
    'database aliases preserve reference and readable category metadata',
    () {
      final outfit = Outfit.fromFirestore('regional', {
        'name': 'Ait Baamrane',
        'gender': ' Female ',
        'style': 'Marocain',
        'category': 'Ait Baamrane',
        'categoryId': 'category-123',
        'active': true,
        'imageUrl': 'display.jpg',
        'promptImageUrl': '',
        'referenceImageUrl': 'reference.png',
        'promptText': 'Preserve the embroidery',
      });
      expect(outfit.gender, 'femme');
      expect(outfit.fullImageUrl, 'display.jpg');
      expect(outfit.thumbnailUrl, 'display.jpg');
      expect(outfit.promptImageUrl, 'reference.png');
      expect(outfit.extraPrompt, 'Preserve the embroidery');
      expect(outfitType(outfit), 'Ait Baamrane');
      expect(
        OutfitRepository.filter(
          [outfit],
          gender: 'female',
          style: 'Marocain',
          category: 'category-123',
        ),
        [outfit],
      );
    },
  );
  test(
    'changing category clears private media and rejects late generation',
    () async {
      final pending = Completer<List<Uint8List>>();
      final session = TryOnSession(generator: (_) => pending.future);
      session.confirm(selection(), Uint8List(1));
      final run = session.generate();
      await Future<void>.delayed(Duration.zero);
      session.setPayment(PaymentStatus.paid);
      session.selectCategory('Amazigh');
      expect(session.gender, 'femme');
      expect(session.style, 'Marocain');
      expect(session.categoryId, 'Amazigh');
      expect(session.outfit, isNull);
      expect(session.capturedPhoto, isNull);
      expect(session.requestId, isNull);
      expect(session.payment, PaymentStatus.pending);
      pending.complete([Uint8List(1)]);
      await run;
      expect(session.results, isEmpty);
      expect(session.status, TryOnStatus.idle);
      session.dispose();
    },
  );
  test('disposing a session ignores pending completion', () async {
    final pending = Completer<List<Uint8List>>();
    final session = TryOnSession(generator: (_) => pending.future);
    session.confirm(selection(), Uint8List(1));
    final run = session.generate();
    await Future<void>.delayed(Duration.zero);
    session.dispose();
    pending.complete([Uint8List(1)]);
    await run;
    expect(session.results, isEmpty);
  });
  testWidgets('empty try-on route opens new entry, never legacy UI', (
    tester,
  ) async {
    await tester.pumpWidget(const DigiwearitApp());
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/try-on');
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Ouvrir la caméra du téléphone'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
