# Digiwearit on the iPhone simulator

The existing Flutter app now has native iOS Firebase configuration for project `vto-with-nano`, app `1:788742730808:ios:097ad6b0f8d1e58d4ba2cd`, bundle ID `com.digiwearit.app`. It uses the same catalogue, Storage and AI generation flow as web.

## On your Mac, once

1. Install Xcode, open it, accept its license, and install an iOS simulator runtime in Xcode Settings > Components. Use a current Xcode compatible with your macOS and Firebase SDK 12.17.0 (Xcode 16.2 or newer).
2. Select Xcode's tools: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer` and `sudo xcodebuild -runFirstLaunch`.
3. Install Flutter (this project uses Flutter 3.41.7 / Dart 3.11.5) and CocoaPods. Check `flutter doctor -v` and resolve its Xcode/CocoaPods findings. The launcher also uses Python 3 supplied with the Xcode command-line tools.
4. Copy the complete `digiwearit2` folder to the Mac, including assets, `pubspec.lock`, `ios`, and `scripts`. Generated Windows build files are not needed. Do not copy just the `ios` directory.

## Run

From the `digiwearit2` directory:

```bash
bash scripts/run_ios_simulator.sh
```

The script regenerates Flutter's local paths, installs pods, boots an available iPhone simulator running iOS 15 or later, and runs the app. No Apple Developer membership, provisioning profile, or signing team is needed for a simulator build. The first pod installation/build can take several minutes and requires internet access.

To use a specific simulator or preload your own test photo:

```bash
SIMULATOR_UDID="your-simulator-uuid" PHOTO_PATH="/absolute/path/photo.jpg" bash scripts/run_ios_simulator.sh
```

You can also drag a JPG/PNG onto Simulator, then tap **Galerie** in the app. Use a physical iPhone to verify live camera capture and the three-second countdown. HEIC selection has a known image_picker simulator limitation; use JPG/PNG for simulator tests.

## Permissions and Firebase

- Camera: declared with the virtual try-on purpose; requested by the camera plugin when capture opens.
- Photos: declared; the system picker accesses the selected image with full metadata requests disabled.
- Microphone: audio capture is disabled; the app does not request microphone access.
- Local network: Flutter adds its debug-only discovery permission when building. Allow it if prompted for hot reload/debugging.
- No location, notification, photo-library-write, or tracking permission is required by this flow. CocoaPods selects Analytics without advertising-ID support.
- Firebase's real `GoogleService-Info.plist` is included in Runner's resources, with matching Dart iOS options. Do not replace it with the web app ID.
- Existing Firestore/Storage rules and AI prompt are unchanged. iOS does not require an Android SHA fingerprint. HTTPS networking needs no broad App Transport Security exception.
- Payment remains the approved demo; email and partner validation require the existing backend integration. This preparation does not turn those into live services.

## Verify on the Mac

Go through gender, style, category, model, Galerie, confirmation, generation and demo payment. A generation attempt uses the existing real AI service and can incur the project's normal usage charges. Check that the actual returned image appears and that Home clears the session.

For a compile-only check:

```bash
flutter build ios --simulator --debug
```

For Xcode debugging, open `ios/Runner.xcworkspace` after running the launcher. A physical device additionally needs a signing team and device trust in Xcode. Denied camera permission can be restored in iOS Settings > Privacy & Security > Camera; restricted access may require changing parental/device restrictions.

Native compilation and simulator execution cannot be verified from the Windows workspace. The final native acceptance check must run on the Mac.

References: [Flutter iOS setup](https://docs.flutter.dev/platform-integration/ios/setup), [Firebase Flutter setup](https://firebase.google.com/docs/flutter/setup), [image_picker iOS notes](https://pub.dev/packages/image_picker).
