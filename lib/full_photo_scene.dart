import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class OverlayGlass extends StatelessWidget {
  const OverlayGlass({
    super.key,
    required this.child,
    this.tint = const Color(0x991e1632),
    this.blur = 22,
    this.borderColor = Colors.white30,
  });
  final Widget child;
  final Color tint, borderColor;
  final double blur;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    ),
  );
}

class FullPhotoScene extends StatelessWidget {
  const FullPhotoScene({
    super.key,
    required this.bytes,
    required this.body,
    required this.footer,
    required this.english,
    required this.onLanguage,
    required this.onBack,
    this.generation = false,
    this.photoKey,
  });
  final Uint8List bytes;
  final Widget body, footer;
  final bool english, generation;
  final VoidCallback onLanguage, onBack;
  final Key? photoKey;
  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: false,
    backgroundColor: Colors.black,
    body: Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: Transform.scale(
            scale: 1.05,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Image.memory(
                bytes,
                key: generation ? photoKey : null,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) =>
                    const ColoredBox(color: Color(0xff211a30)),
              ),
            ),
          ),
        ),
        if (!generation)
          Image.memory(
            bytes,
            key: photoKey,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        if (generation) const ColoredBox(color: Color(0x4d0c0823)),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x550a0823),
                  Colors.transparent,
                  Colors.transparent,
                  Color(0x660a0823),
                ],
                stops: [0, .22, .6, 1],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: onBack,
                        tooltip: english ? 'Back' : 'Retour',
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Image.asset(
                            'lib/logo digiwearit.png',
                            height: 38,
                          ),
                        ),
                      ),
                      PopupMenuButton<bool>(
                        tooltip: english ? 'Language' : 'Langue',
                        initialValue: english,
                        onSelected: (value) {
                          if (value != english) onLanguage();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: false, child: Text('Français')),
                          PopupMenuItem(value: true, child: Text('English')),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.language,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                english ? 'EN' : 'FR',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              const Icon(
                                Icons.expand_more,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) => FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: box.maxWidth,
                        height: box.maxHeight < 180 ? 180 : box.maxHeight,
                        child: body,
                      ),
                    ),
                  ),
                ),
                footer,
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
