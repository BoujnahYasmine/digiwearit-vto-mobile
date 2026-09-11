import 'dart:async';
import 'package:flutter/material.dart';
import 'firebase_startup.dart';
import 'admin_screen.dart';
import 'welcome_screen.dart';
import 'universe_screen.dart';
import 'style_screen.dart';
import 'style_selection.dart';
import 'outfit_screen.dart';
import 'model_screen.dart';
import 'photo_screen.dart';
import 'generation_screen.dart';
import 'outfit_selection.dart';
import 'partner_screen.dart';
import 'try_on_session.dart';
export 'outfit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DigiwearitApp());
  unawaited(
    FirebaseStartup.ensureReady().catchError((Object error) {
      debugPrint('Firebase startup unavailable: $error');
    }),
  );
}

class DigiwearitApp extends StatelessWidget {
  const DigiwearitApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Digiwearit',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff5146f5)),
    ),
    initialRoute: '/',
    routes: {
      '/': (_) => const WelcomeScreen(),
      '/universe': (context) => UniverseScreen(
        initialEnglish: ModalRoute.of(context)?.settings.arguments == true,
      ),
      '/style': (context) => StyleScreen(
        selection:
            ModalRoute.of(context)?.settings.arguments as StyleSelection? ??
            const StyleSelection(),
      ),
      '/outfits': (context) => OutfitScreen(
        categoryMode: true,
        selection:
            ModalRoute.of(context)?.settings.arguments as StyleSelection? ??
            const StyleSelection(),
      ),
      '/model': (context) {
        final selection = ModalRoute.of(context)?.settings.arguments;
        return selection is OutfitSelection
            ? ModelScreen(selection: selection)
            : const OutfitScreen();
      },
      '/try-on': (context) {
        final arguments = ModalRoute.of(context)?.settings.arguments;
        if (arguments is OutfitSelection) {
          return PhotoScreen(
            selection: arguments,
            onContinue: (context, bytes) async {
              TryOnSession.current.confirm(arguments, bytes);
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      FirebaseReady(builder: (_) => const GenerationScreen()),
                ),
              );
            },
          );
        }
        return const WelcomeScreen();
      },
      '/partner': (context) => PartnerScreen(
        english: ModalRoute.of(context)?.settings.arguments == true,
      ),
      '/admin': (_) => FirebaseReady(builder: (_) => const AdminScreen()),
    },
  );
}
