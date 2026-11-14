import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';

const digiInk = Color(0xff171451);
const digiGradient = LinearGradient(
  colors: [Color(0xff245cff), Color(0xff8245f6), Color(0xfffa4ca7)],
);

class DigiGlass extends StatelessWidget {
  const DigiGlass({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xfff3edf7).withValues(alpha: .9),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white70),
    ),
    padding: const EdgeInsets.all(14),
    child: child,
  );
}

/// The Digiwearit slogan, centred at the bottom of the pages.
class DigiSlogan extends StatelessWidget {
  const DigiSlogan({
    super.key,
    this.color = const Color(0xffa68eba),
    this.fontSize = 9,
  });
  static const text = '—  DIGITALLY WEAR IT  —';
  static const _spacing = 3.0;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        // Letter spacing also follows the last character: balance it so
        // the slogan sits exactly in the middle.
        padding: const EdgeInsets.only(left: _spacing),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            letterSpacing: _spacing,
          ),
        ),
      ),
    ),
  );
}

class DigiButton extends StatelessWidget {
  const DigiButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: secondary ? null : digiGradient,
      color: secondary ? Colors.white54 : null,
      borderRadius: BorderRadius.circular(20),
    ),
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      child: Text(
        label,
        maxLines: 2,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: secondary ? digiInk : Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class DigiHeader extends StatelessWidget {
  const DigiHeader({
    super.key,
    this.english = false,
    this.onLanguage,
    this.onBack,
  });
  final bool english;
  final VoidCallback? onLanguage, onBack;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Row(
      children: [
        if (onBack != null)
          IconButton(
            tooltip: english ? 'Back' : 'Retour',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: digiInk),
          ),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Image.asset('lib/logo digiwearit.png', width: 160),
          ),
        ),
        if (onLanguage != null)
          TextButton(
            onPressed: onLanguage,
            child: Text(
              english ? 'EN' : 'FR',
              style: const TextStyle(color: digiInk),
            ),
          ),
      ],
    ),
  );
}

/// One viewport: only the content area may scroll; the action area never does.
class DigiScaffold extends StatelessWidget {
  const DigiScaffold({
    super.key,
    required this.body,
    required this.footer,
    this.header,
    this.background,
    this.title,
    this.resizeForKeyboard = true,
  });
  final Widget body, footer;
  final Widget? header, background;
  final String? title;
  final bool resizeForKeyboard;
  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: resizeForKeyboard,
    body: Stack(
      fit: StackFit.expand,
      children: [
        background ??
            Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/welcome_boutique.png', fit: BoxFit.cover),
                ColoredBox(
                  color: const Color(0xffddcfe4).withValues(alpha: .83),
                ),
              ],
            ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: header ?? const DigiHeader(),
              ),
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Text(
                    title!,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: digiInk,
                      fontWeight: FontWeight.bold,
                      fontSize: 23,
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: body,
                ),
              ),
              Padding(padding: const EdgeInsets.all(12), child: footer),
            ],
          ),
        ),
      ],
    ),
  );
}

class PhotoBackdrop extends StatelessWidget {
  const PhotoBackdrop({super.key, required this.bytes});
  final Uint8List bytes;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, e, s) => const ColoredBox(color: Color(0xffb5a1bd)),
        ),
      ),
      const ColoredBox(color: Color(0x66532561)),
    ],
  );
}

/// Rotating loading ring drawn entirely with the Digiwearit gradient.
class DigiSpinner extends StatefulWidget {
  const DigiSpinner({super.key, this.size = 82, this.strokeWidth = 5});
  final double size;
  final double strokeWidth;
  @override
  State<DigiSpinner> createState() => _DigiSpinnerState();
}

class _DigiSpinnerState extends State<DigiSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size,
    child: RotationTransition(
      turns: _spin,
      child: CustomPaint(painter: _DigiRingPainter(widget.strokeWidth)),
    ),
  );
}

class _DigiRingPainter extends CustomPainter {
  const _DigiRingPainter(this.stroke);
  final double stroke;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    const sweep = 4.6; // radians (~265°), leaves a small gap
    canvas.drawCircle(
      rect.center,
      rect.width / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = const Color(0x338245f6),
    );
    canvas.drawArc(
      rect,
      0,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          endAngle: sweep,
          colors: [Color(0xff245cff), Color(0xff8245f6), Color(0xfffa4ca7)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_DigiRingPainter old) => old.stroke != stroke;
}
