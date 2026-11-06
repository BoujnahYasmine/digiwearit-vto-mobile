import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Shows the whole result, uncropped, so the Digiwearit logo baked into the
/// image is visible exactly as in the e-mail. A blurred copy fills the edges.
class ResultPhoto extends StatelessWidget {
  const ResultPhoto({super.key, required this.bytes});
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
        ),
        const ColoredBox(color: Color(0x66050514)),
        Image.memory(
          bytes,
          key: const ValueKey('result-photo'),
          fit: BoxFit.contain,
          alignment: Alignment.center,
          gaplessPlayback: true,
        ),
      ],
    ),
  );
}
