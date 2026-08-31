import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Firebase configuration for the Digiwearit web application.
///
/// Android and iOS still require their native Firebase configuration files
/// before Firebase can be initialized on those platforms.
abstract final class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyASifVA5Z2YtQntnTkpJxdDpvvJKR8Fk94',
    authDomain: 'vto-with-nano.firebaseapp.com',
    projectId: 'vto-with-nano',
    storageBucket: 'vto-with-nano.firebasestorage.app',
    messagingSenderId: '788742730808',
    appId: '1:788742730808:web:e096620aaa5c43a54ba2cd',
    measurementId: 'G-CXSNVEY7DY',
  );

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
      'Firebase is currently configured only for the web app.',
    );
  }
}
