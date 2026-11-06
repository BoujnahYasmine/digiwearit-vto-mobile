import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Firebase configuration for the registered Digiwearit web, iOS and Android apps.
///
/// Other native platforms still require their Firebase configuration files
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

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC4XjpGtl9rULJ0YadmJTxXVLdUg-ODtxY',
    appId: '1:788742730808:ios:097ad6b0f8d1e58d4ba2cd',
    messagingSenderId: '788742730808',
    projectId: 'vto-with-nano',
    storageBucket: 'vto-with-nano.firebasestorage.app',
    iosBundleId: 'com.digiwearit.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA_bACNlBssYPtk82Nwa79XBnzSyN-15Ks',
    appId: '1:788742730808:android:7f4da01e495554534ba2cd',
    messagingSenderId: '788742730808',
    projectId: 'vto-with-nano',
    storageBucket: 'vto-with-nano.firebasestorage.app',
  );
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.iOS) return ios;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError(
      'Firebase is currently configured for web, iOS and Android. Configure this platform before running it.',
    );
  }
}
