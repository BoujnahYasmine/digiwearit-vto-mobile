import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Quiet looping music for both parcours (simple and mirror), with no
/// customer control. Starts on the first touch, since browsers block sound
/// before one, pauses while the app is in the background, and stays silent
/// when `assets/music/background.mp3` is missing.
class BackgroundMusic extends StatefulWidget {
  const BackgroundMusic({super.key, required this.child});
  final Widget child;

  static const asset = 'music/background.mp3';
  static const volume = .15;

  @override
  State<BackgroundMusic> createState() => _BackgroundMusicState();
}

class _BackgroundMusicState extends State<BackgroundMusic> {
  AudioPlayer? _player;
  AppLifecycleListener? _lifecycle;
  bool _started = false;

  // Widget tests have no audio plugin.
  static bool get _available =>
      kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST');

  Future<void> _start() async {
    if (_started || !_available) return;
    _started = true;
    try {
      await rootBundle.load('assets/${BackgroundMusic.asset}');
    } catch (_) {
      debugPrint('Background music not found: assets/${BackgroundMusic.asset}');
      return;
    }
    try {
      final player = _player = AudioPlayer();
      // Mix with other sounds rather than taking exclusive audio focus.
      await player.setAudioContext(
        AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
        ).build(),
      );
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(BackgroundMusic.volume);
      await player.play(AssetSource(BackgroundMusic.asset));
      _lifecycle = AppLifecycleListener(
        onHide: () => player.pause(),
        onShow: () => player.resume(),
      );
    } catch (error) {
      debugPrint('Background music unavailable: $error');
    }
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => _start(),
    child: widget.child,
  );
}
