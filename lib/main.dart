import 'experience_failure.dart';
import 'outfit_repository.dart';
import 'mirror/mirror_access_guard.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_startup.dart';
import 'admin_screen.dart';
import 'background_music.dart';
import 'welcome_screen.dart';
import 'universe_screen.dart';
import 'style_screen.dart';
import 'style_selection.dart';
import 'outfit_screen.dart';

import 'photo_screen.dart';
import 'generation_screen.dart';
import 'store_payment.dart';
import 'outfit_selection.dart';
import 'try_on_session.dart';
import 'mirror/mirror_setup_screen.dart';
import 'mirror/mirror_home_screen.dart';
import 'mirror/mirror_catalogues_screen.dart';
import 'mirror/mirror_outfits_screen.dart';
import 'mirror/mirror_camera_screen.dart';
import 'mirror/mirror_generation_screen.dart';
import 'mirror/mirror_result_screen.dart';
import 'outfit.dart';
export 'outfit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Customers never see a crash box or raw error: in release a broken piece
  // of screen is left blank and unexpected errors only reach the logs.
  // Debug builds keep Flutter's red error screen for developers.
  if (kReleaseMode) {
    ErrorWidget.builder = (_) => const SizedBox.shrink();
  }
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unexpected error (hidden from customer): $error');
    return true;
  };
  StorePayment.instance.start();
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
    builder: (context, child) =>
        BackgroundMusic(child: child ?? const SizedBox.shrink()),
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff5146f5)),
    ),
    initialRoute: '/',
    routes:
        {
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
          '/try-on': (context) {
            final arguments = ModalRoute.of(context)?.settings.arguments;
            if (arguments is OutfitSelection) {
              return PhotoScreen(
                selection: arguments,
                makeup: normalizedGender(arguments.gender) == 'femme',
                onContinue: (context, bytes) async {
                  final latest = await OutfitRepository()
                      .getOutfitById(arguments.outfit.id, fromServer: true)
                      .timeout(const Duration(seconds: 15));
                  if (!context.mounted) return;
                  if (latest == null || !latest.active) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(Friendly.outfitUnavailable)),
                    );
                    return;
                  }
                  final refreshed = OutfitSelection(
                    outfit: latest,
                    gender: arguments.gender,
                    english: arguments.english,
                    style: latest.style.isEmpty
                        ? arguments.style
                        : latest.style,
                    preferredColor: arguments.preferredColor,
                    preferredColorName: arguments.preferredColorName,
                  );
                  TryOnSession.current.confirm(refreshed, bytes);
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FirebaseReady(
                        builder: (_) => const GenerationScreen(),
                      ),
                    ),
                  );
                },
              );
            }
            return const WelcomeScreen();
          },
          '/admin': (_) => FirebaseReady(builder: (_) => const AdminScreen()),
          '/mirror': (_) => const MirrorSetupScreen(),
          '/mirror/home': (_) => const MirrorHomeScreen(),
          '/mirror/universe': (context) => UniverseScreen(
            onBack: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false),
            onSelected: (gender, english) => Navigator.of(context).pushNamed(
              '/mirror/catalogues',
              arguments: StyleSelection(gender: gender, english: english),
            ),
          ),
          '/mirror/catalogues': (context) => MirrorCataloguesScreen(
            initialEnglish:
                (ModalRoute.of(context)?.settings.arguments as StyleSelection?)
                    ?.english ??
                false,
            gender:
                (ModalRoute.of(context)?.settings.arguments as StyleSelection?)
                    ?.gender,
          ),
          '/mirror/outfits': (_) => const MirrorOutfitsScreen(),
          '/mirror/camera': (_) => const MirrorCameraScreen(),
          '/mirror/generation': (_) => const MirrorGenerationScreen(),
          '/mirror/result': (_) => const MirrorResultScreen(),
        }.map(
          (name, builder) => MapEntry(
            name,
            (BuildContext context) => name.startsWith('/mirror/')
                ? MirrorAccessGuard(child: builder(context))
                : builder(context),
          ),
        ),
  );
}
