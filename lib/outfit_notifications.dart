import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_startup.dart';
import 'outfit.dart';
import 'outfit_repository.dart';
import 'outfit_selection.dart';
import 'try_on_session.dart';

/// "New outfit" push notifications of the simple journey (Android and iOS).
///
/// Phones subscribe to [topic] the first time the customer enters the simple
/// journey (never in mirror mode); the server pushes when an outfit is added.
/// Tapping the notification opens the try-on of the new outfit.
class OutfitNotifications {
  OutfitNotifications._();
  static final instance = OutfitNotifications._();
  static const topic = 'new_outfits';

  /// Set by the app so a tap on a notification can open the journey.
  GlobalKey<NavigatorState>? navigator;
  GlobalKey<ScaffoldMessengerState>? messenger;

  bool _listening = false;

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Asks permission (Android 13+, iOS) and subscribes, or unsubscribes when
  /// the customer turned them off in the profile.
  Future<void> enable(bool on) async {
    if (!supported) return;
    try {
      await FirebaseStartup.ensureReady();
      final messaging = FirebaseMessaging.instance;
      if (!on) {
        await messaging.unsubscribeFromTopic(topic);
        return;
      }
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      await messaging.subscribeToTopic(topic);
      _listen();
    } catch (error) {
      debugPrint('Outfit notifications unavailable: $error');
    }
  }

  void _listen() {
    if (_listening) return;
    _listening = true;
    final messaging = FirebaseMessaging.instance;
    // App closed, then opened from the notification.
    messaging.getInitialMessage().then((m) {
      if (m != null) _open(m);
    });
    // App in the background, opened from the notification.
    FirebaseMessaging.onMessageOpenedApp.listen(_open);
    // App open: the system shows nothing, so a banner invites to try it.
    FirebaseMessaging.onMessage.listen((m) {
      final note = m.notification;
      if (note == null) return;
      messenger?.currentState?.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          content: Text('${note.title ?? ''}\n${note.body ?? ''}'.trim()),
          action: SnackBarAction(label: 'Essayer', onPressed: () => _open(m)),
        ),
      );
    });
  }

  /// Opens the try-on of the outfit announced by the notification; the
  /// gender choice stays behind it, so "back" returns to the journey.
  Future<void> _open(RemoteMessage message) async {
    if (message.data['type'] != 'new_outfit') return;
    final nav = navigator?.currentState;
    if (nav == null) return;
    nav.pushNamedAndRemoveUntil('/universe', (route) => route.isFirst);
    final id = message.data['outfitId'];
    if (id is! String || id.isEmpty) return;
    Outfit? outfit;
    try {
      outfit = await OutfitRepository()
          .getOutfitById(id, fromServer: true)
          .timeout(const Duration(seconds: 15));
    } catch (error) {
      debugPrint('Notified outfit unavailable: $error');
    }
    if (outfit == null || !outfit.active) return;
    final gender = normalizedGender(outfit.gender) == 'homme'
        ? 'homme'
        : 'femme';
    final style = outfit.style.isEmpty ? 'Marocain' : outfit.style;
    final selection = OutfitSelection(
      outfit: outfit,
      outfits: [outfit],
      gender: gender,
      english: false,
      style: style,
    );
    TryOnSession.current
      ..reset()
      ..selectGender(gender)
      ..selectStyle(style)
      ..selectCategory(outfitType(outfit))
      ..selectOutfit(selection);
    navigator?.currentState?.pushNamed('/try-on', arguments: selection);
  }
}
