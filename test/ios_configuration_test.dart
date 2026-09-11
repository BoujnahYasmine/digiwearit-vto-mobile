import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/firebase_options.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  test('iOS selects its registered Firebase app instead of web options', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final options = DefaultFirebaseOptions.currentPlatform;
    expect(options, same(DefaultFirebaseOptions.ios));
    expect(options.appId, isNot(DefaultFirebaseOptions.web.appId));
    expect(options.projectId, DefaultFirebaseOptions.web.projectId);
    expect(options.iosBundleId, 'com.digiwearit.app');
  });
  test('iOS permissions and native build settings match the camera flow', () {
    final info = File('ios/Runner/Info.plist').readAsStringSync();
    expect(info, contains('NSCameraUsageDescription'));
    expect(info, contains('NSPhotoLibraryUsageDescription'));
    expect(info, isNot(contains('NSMicrophoneUsageDescription')));
    final podfile = File('ios/Podfile').readAsStringSync();
    expect(podfile, contains("platform :ios, '15.0'"));
    expect(podfile, contains('use_frameworks! :linkage => :static'));
    expect(
      File('lib/camera_service.dart').readAsStringSync(),
      contains('enableAudio: false'),
    );
  });
  test('native plist matches every required Dart Firebase identifier', () {
    final plist = File(
      'ios/Runner/GoogleService-Info.plist',
    ).readAsStringSync();
    String? field(String key) => RegExp(
      '<key>$key</key>\\s*<string>([^<]+)</string>',
    ).firstMatch(plist)?.group(1);
    final options = DefaultFirebaseOptions.ios;
    expect(field('GOOGLE_APP_ID'), options.appId);
    expect(field('API_KEY'), options.apiKey);
    expect(field('GCM_SENDER_ID'), options.messagingSenderId);
    expect(field('PROJECT_ID'), options.projectId);
    expect(field('STORAGE_BUCKET'), options.storageBucket);
    expect(field('BUNDLE_ID'), options.iosBundleId);
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    expect(
      project,
      contains('PRODUCT_BUNDLE_IDENTIFIER = ${options.iosBundleId};'),
    );
    expect(project, contains('GoogleService-Info.plist in Resources'));
  });
}
