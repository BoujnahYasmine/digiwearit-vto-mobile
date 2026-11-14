import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'photo_check.dart';
import 'capture_processing.dart';
import 'mobile_layout.dart';

class PhotoReviewScreen extends StatefulWidget {
  const PhotoReviewScreen({
    super.key,
    required this.bytes,
    required this.onContinue,
    this.english = false,
    this.check,
    this.pending,
    this.previewMirrored = false,
  });

  /// The photo, or with [pending] the raw still shown while it is prepared.
  final Uint8List bytes;

  /// The prepared photo (retouch and light check) still being computed: the
  /// review opens at once on [bytes] and switches to it when ready.
  final Future<ProcessedCapture>? pending;
  final bool previewMirrored;
  final bool english;

  /// Automatic light and camera-quality check of the photo; problems are
  /// shown as tips and the customer may still continue.
  final PhotoCheck? check;
  final Future<void> Function(BuildContext, Uint8List) onContinue;
  @override
  State<PhotoReviewScreen> createState() => _PhotoReviewScreenState();
}

class _PhotoReviewScreenState extends State<PhotoReviewScreen> {
  bool busy = false, valid = false, failed = false;
  late Uint8List bytes = widget.bytes;
  late PhotoCheck? check = widget.check;
  late bool mirrored = widget.pending != null && widget.previewMirrored;
  @override
  void initState() {
    super.initState();
    final pending = widget.pending;
    if (pending == null) {
      validate();
      return;
    }
    pending.then(
      (shot) {
        if (!mounted) return;
        setState(() {
          bytes = shot.bytes;
          check = shot.check;
          mirrored = false;
        });
        validate();
      },
      onError: (Object error) {
        if (mounted) setState(() => failed = true);
      },
    );
  }

  Future<void> validate() async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      frame.image.dispose();
      codec.dispose();
      if (mounted) setState(() => valid = true);
    } catch (_) {
      if (mounted) setState(() => valid = false);
    }
  }

  late bool english = widget.english;
  Future<void> next() async {
    if (busy || !valid) return;
    setState(() => busy = true);
    try {
      await widget.onContinue(context, bytes);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff15131e),
    body: Stack(
      fit: StackFit.expand,
      children: [
        Transform.flip(
          flipX: mirrored,
          child: Image.memory(
            bytes,
            key: const ValueKey('review-photo'),
            gaplessPlayback: true,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, e, s) => Center(
              child: Text(
                english
                    ? 'Unreadable photo. Please retake it.'
                    : 'Photo illisible. Reprenez une photo.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x4d0a0823),
                  Colors.transparent,
                  Colors.transparent,
                  Color(0x730a0823),
                ],
                stops: [0, .22, .65, 1],
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
                      _glass(
                        IconButton(
                          tooltip: english ? 'Back' : 'Retour',
                          onPressed: busy ? null : () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        blur: 12,
                        opacity: .15,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Image.asset(
                            'lib/logo digiwearit.png',
                            height: 36,
                          ),
                        ),
                      ),
                      // Language is chosen on the home page only.
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const Spacer(),
                _glass(
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          english
                              ? 'Everything look good?'
                              : 'Tout est parfait ?',
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black38, blurRadius: 5),
                            ],
                          ),
                        ),
                        if (check?.lighting case final issue?) ...[
                          const SizedBox(height: 8),
                          PhotoTip(
                            lightingAdvice(issue, english: english),
                            key: const ValueKey('photo-lighting-warning'),
                          ),
                        ],
                        if (check?.quality case final issue?) ...[
                          const SizedBox(height: 8),
                          PhotoTip(
                            qualityAdvice(issue, english: english),
                            key: const ValueKey('photo-quality-warning'),
                          ),
                        ],
                        const SizedBox(height: 5),
                        Text(
                          failed
                              ? (english
                                    ? 'This photo could not be prepared. Please retake it.'
                                    : 'Cette photo n’a pas pu être préparée. Reprenez-la.')
                              : check?.lighting != null ||
                                    check?.quality != null
                              ? (english
                                    ? 'Retake for a better try-on, or continue.'
                                    : 'Reprenez pour un meilleur essayage, ou continuez.')
                              : english
                              ? 'Check your photo before continuing.'
                              : 'Vérifiez votre photo avant de continuer.',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black38, blurRadius: 5),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: DigiButton(
                                key: const ValueKey('photo-retake'),
                                secondary: true,
                                label: english ? '↻ Retake' : '↻ Reprendre',
                                onPressed: busy
                                    ? null
                                    : () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DigiButton(
                                key: const ValueKey('photo-continue'),
                                label: english ? '✓ Continue' : '✓ Continuer',
                                onPressed: busy || !valid ? null : next,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  blur: 20,
                  opacity: .18,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _glass(
    Widget child, {
    required double blur,
    required double opacity,
  }) => ClipRRect(
    borderRadius: BorderRadius.circular(26),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white30),
        ),
        child: child,
      ),
    ),
  );
}
