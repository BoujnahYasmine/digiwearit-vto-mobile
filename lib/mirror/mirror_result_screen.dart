import 'mirror_review_service.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../delivery_screen.dart';
import '../full_photo_scene.dart';
import '../mobile_layout.dart';
import '../rating_sheet.dart';
import '../result_photo.dart';
import 'mirror_tryon_controller.dart';
import 'mirror_delivery_service.dart';

/// Approved Digiwearit result design, without any payment step. Shows the
/// watermarked image, sends it by email and offers reset actions.
class MirrorResultScreen extends StatefulWidget {
  const MirrorResultScreen({super.key, this.controller});
  final MirrorTryOnController? controller;
  @override
  State<MirrorResultScreen> createState() => _MirrorResultScreenState();
}

class _MirrorResultScreenState extends State<MirrorResultScreen> {
  late final MirrorTryOnController controller =
      widget.controller ?? MirrorTryOnController.current;
  bool presenting = false;
  double? _sheetExtent;

  Uint8List get image =>
      controller.brandedGeneratedImage ??
      controller.generatedImage ??
      Uint8List(0);

  void _tryAnotherOutfit() {
    controller.tryAnotherOutfit();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/mirror/catalogues', (route) => false);
  }

  void _returnHome() {
    controller.returnHome();
    imageCache.clear();
    imageCache.clearLiveImages();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/mirror/home', (route) => false);
  }

  Future<void> _email() async {
    if (presenting) return;
    setState(() => presenting = true);
    final sent = await showDeliverySheet(
      context,
      bytes:
          controller.brandedGeneratedImage ??
          controller.generatedImage ??
          Uint8List(0),
      sender: MirrorDeliveryService.send,
      resultId: controller.requestId ?? 'mirror',
    );
    if (!mounted) return;
    if (sent != true) {
      setState(() => presenting = false);
      return;
    }
    await _review();
  }

  Future<void> _finish() async {
    if (presenting) return;
    setState(() => presenting = true);
    await _review();
  }

  Future<void> _review() async {
    final choice = await showRatingSheet(
      context,
      sender: MirrorReviewService.send,
      tryOnId: controller.requestId,
      outfitId: controller.selectedOutfitId,
    );
    if (!mounted) return;
    setState(() => presenting = false);
    if (choice == EndChoice.another) {
      _tryAnotherOutfit();
    } else if (choice == EndChoice.finish) {
      _returnHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.sizeOf(context).height < 700 ||
        MediaQuery.textScalerOf(context).scale(16) > 22;
    final bytes = image;
    final extent = _sheetExtent ?? (compact ? .38 : .42);
    final outfitName = controller.selectedOutfit?.name ?? 'Tenue';
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xff11101b),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (bytes.isNotEmpty)
            ResultPhoto(bytes: controller.generatedImage ?? bytes)
          else
            const ColoredBox(color: Color(0xff11101b)),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x6b050514),
                    Colors.transparent,
                    Colors.transparent,
                    Color(0x8c050514),
                  ],
                  stops: [0, .22, .65, 1],
                ),
              ),
            ),
          ),
          if (bytes.isNotEmpty)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 68,
              left: 8,
              right: 8,
              bottom: presenting
                  ? 12
                  : MediaQuery.sizeOf(context).height * extent + 8,
              child: Image.memory(
                bytes,
                key: const ValueKey('mirror-branded-preview'),
                fit: BoxFit.contain,
                gaplessPlayback: true,
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
                        _control(
                          IconButton(
                            tooltip: 'Retour',
                            onPressed: presenting ? null : _tryAnotherOutfit,
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Image.asset(
                              'lib/logo digiwearit.png',
                              height: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.checkroom,
                            color: Color(0xff6e52dc),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              outfitName.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: digiInk,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          if (!presenting)
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                if (_sheetExtent != notification.extent) {
                  setState(() => _sheetExtent = notification.extent);
                }
                return false;
              },
              child: DraggableScrollableSheet(
                key: const ValueKey('mirror-result-sheet'),
                initialChildSize: compact ? .38 : .42,
                minChildSize: .08,
                maxChildSize: .72,
                snap: true,
                snapSizes: [compact ? .38 : .42],
                builder: (context, scrollController) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: ColoredBox(
                      color: const Color(0xf2130f2a),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        child: SafeArea(
                          top: false,
                          child: _resultPanel(compact),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _control(Widget child) => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0x4d1e1937),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white24),
        ),
        child: child,
      ),
    ),
  );

  Widget _resultPanel(bool compact) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 40,
          offset: Offset(0, -10),
        ),
      ],
    ),
    child: OverlayGlass(
      tint: const Color(0xd6130f2a),
      blur: 24,
      borderColor: Colors.white24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: compact ? 90 : 150,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width - 52,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xffb5abcc),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 14),
                    SizedBox(
                      height: compact ? 34 : 54,
                      child: Container(
                        padding: EdgeInsets.all(compact ? 5 : 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: digiGradient,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xff9c59ef,
                              ).withValues(alpha: .28),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xffd6c2fb),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: digiInk,
                            size: compact ? 20 : 30,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 6 : 12),
                    Text(
                      'Votre essayage est prêt ✨',
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: compact ? 18 : 23,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Que souhaitez-vous faire maintenant ?',
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xffb9aed0),
                        fontSize: compact ? 11 : 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 10 : 16),
          DigiButton(
            key: const ValueKey('mirror-result-email'),
            label: '✉ Recevoir ma photo',
            onPressed: _email,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white38),
            ),
            child: TextButton(
              onPressed: _tryAnotherOutfit,
              style: TextButton.styleFrom(
                minimumSize: Size(0, compact ? 44 : 52),
              ),
              child: Text(
                '↻ Essayer une autre tenue',
                maxLines: 2,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          TextButton(
            onPressed: _finish,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(vertical: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Retour à l’accueil',
              maxLines: 1,
              style: TextStyle(color: Color(0xffc7d5f7), fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}
