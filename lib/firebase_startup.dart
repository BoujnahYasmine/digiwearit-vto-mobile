import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';

import 'firebase_options.dart';

/// One shared initialization attempt for all features that need Firebase.
abstract final class FirebaseStartup {
  static Future<void>? _pending;

  static Future<void> ensureReady() =>
      _pending ??= _initialize().catchError((Object error, StackTrace stack) {
        _pending = null;
        Error.throwWithStackTrace(error, stack);
      });

  static Future<void> _initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Analytics must never prevent the catalogue or camera from opening.
    unawaited(_enableAnalytics());
  }

  static Future<void> _enableAnalytics() async {
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    } catch (error) {
      debugPrint('Analytics unavailable: $error');
    }
  }
}

/// Keep local onboarding usable while network-backed features initialize.
class FirebaseReady extends StatefulWidget {
  const FirebaseReady({
    super.key,
    required this.builder,
    this.initialize = FirebaseStartup.ensureReady,
    this.timeout = const Duration(seconds: 20),
  });

  final WidgetBuilder builder;
  final Future<void> Function() initialize;
  final Duration timeout;

  @override
  State<FirebaseReady> createState() => _FirebaseReadyState();
}

class _FirebaseReadyState extends State<FirebaseReady> {
  late Future<void> _ready = _initialize();

  Future<void> _initialize() =>
      Future<void>.sync(widget.initialize).timeout(widget.timeout);

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _ready,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError) {
        return widget.builder(context);
      }
      return Scaffold(
        backgroundColor: const Color(0xffe1d9e6),
        appBar: AppBar(title: const Text('Digiwearit')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (snapshot.hasError) ...[
                  const Icon(Icons.cloud_off_outlined, size: 48),
                  const SizedBox(height: 20),
                  const Text(
                    'Connexion au service indisponible.\nVérifiez votre connexion et réessayez.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => setState(() {
                      _ready = _initialize();
                    }),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ] else ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  const Text(
                    'Connexion à votre collection…',
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
