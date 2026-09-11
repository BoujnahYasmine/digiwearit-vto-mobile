import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/welcome_screen.dart';
import 'fixtures.dart';

void main() {
  for (final size in phones) {
    testWidgets('home actions visible at $size', (tester) async {
      viewport(tester, size);
      await tester.pumpWidget(
        app(
          const WelcomeScreen(),
          routes: {
            '/universe': (_) => const Scaffold(body: Text('Public')),
            '/partner': (_) => const Scaffold(body: Text('Partner')),
          },
        ),
      );
      await tester.pumpAndSettle();
      visible(tester, find.byKey(const ValueKey('personal-start')));
      visible(tester, find.byKey(const ValueKey('partner-start')));
      expect(find.text('Commencer l’essayage'), findsOneWidget);
      await tester.tap(find.text('FR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Start your try-on'), findsOneWidget);
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();
      final partner = tester.getRect(
        find.byKey(const ValueKey('partner-start')),
      );
      await tester.tapAt(Offset(partner.left + 16, partner.center.dy));
      await tester.pumpAndSettle();
      expect(find.text('Partner'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
