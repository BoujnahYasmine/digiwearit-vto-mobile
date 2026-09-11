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
