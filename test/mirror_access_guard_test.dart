import 'dart:async';
import 'package:digiwearit2/mirror/mirror_access_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/mirror/mirror_access_guard.dart';

void main() {
  testWidgets(
    'Suspension hides a running mirror and retry restores authorized access',
    (tester) async {
      var active = true;
      var checks = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MirrorAccessGuard(
            verifyAccess: () async {
              checks++;
              if (!active) throw StateError('suspended');
            },
            child: const Text('Private partner camera'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Private partner camera'), findsOneWidget);
      active = false;
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(find.text('Private partner camera'), findsNothing);
      active = true;
      await tester.tap(find.text('Reessayer'));
      await tester.pumpAndSettle();
      expect(find.text('Private partner camera'), findsOneWidget);
      expect(checks, 3);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('navigation keeps content visible while access is rechecked', (
    tester,
  ) async {
    final access = MirrorAccessState();
    await access.check(() async {});
    final pending = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: MirrorAccessGuard(
          accessState: access,
          verifyAccess: () => pending.future,
          child: const Text('Next mirror step'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Next mirror step'), findsOneWidget);
    pending.completeError(StateError('revoked'));
    await tester.pumpAndSettle();
    expect(find.text('Next mirror step'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    access.dispose();
  });

  test('session reset rejects stale verification responses', () async {
    final access = MirrorAccessState();
    final pending = Completer<void>();
    final request = access.check(() => pending.future);
    access.reset();
    pending.complete();
    await request;
    expect(access.allowed, false);
    expect(access.checking, false);
    access.dispose();
  });
}
