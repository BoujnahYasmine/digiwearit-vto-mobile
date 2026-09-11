import 'dart:async';
import 'package:digiwearit2/firebase_startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('online feature waits for Firebase before building', (
    tester,
  ) async {
    final ready = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: FirebaseReady(
          initialize: () => ready.future,
          builder: (_) => const Text('Online feature'),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Online feature'), findsNothing);
    ready.complete();
    await tester.pump();
    expect(find.text('Online feature'), findsOneWidget);
  });

  testWidgets('failed initialization can retry', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: FirebaseReady(
          initialize: () async {
            if (++attempts == 1) throw StateError('offline');
          },
          builder: (_) => const Text('Online feature'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Réessayer'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Online feature'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('stalled initialization times out and can recover', (
    tester,
  ) async {
    final ready = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: FirebaseReady(
          initialize: () => ready.future,
          timeout: const Duration(seconds: 2),
          builder: (_) => const Text('Online feature'),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('Réessayer'), findsOneWidget);
    ready.complete();
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Online feature'), findsOneWidget);
  });
}
