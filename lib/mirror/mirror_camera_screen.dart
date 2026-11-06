import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../photo_screen.dart';
import 'mirror_tryon_controller.dart';

/// Mirror camera flow. Reuses the approved Digiwearit camera UI (PhotoScreen
/// plus its photo review with “Reprendre” / “Continuer”). The confirmed,
/// normalized bytes go to the mirror controller before generation starts.
class MirrorCameraScreen extends StatelessWidget {
  const MirrorCameraScreen({super.key});

  Future<void> _continue(BuildContext context, Uint8List bytes) async {
    final controller = MirrorTryOnController.current;
    await controller.confirmPhoto(bytes);
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/mirror/generation', (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) => PhotoScreen(
    makeup: MirrorTryOnController.current.isFemaleJourney,
    initializeCamera: true,
    english: false,
    onContinue: _continue,
  );
}
