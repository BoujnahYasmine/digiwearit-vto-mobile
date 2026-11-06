import '../experience_failure.dart';
import 'package:flutter/material.dart';

import '../full_photo_scene.dart';
import '../mobile_layout.dart';
import 'mirror_tryon_controller.dart';

/// Full-screen premium loading while the backend AI creates the try-on.
/// Prevents duplicate requests and blocks navigation during active
/// generation; never shows fake percentages.
class MirrorGenerationScreen extends StatefulWidget {
  const MirrorGenerationScreen({super.key, this.controller});
  final MirrorTryOnController? controller;
  @override
  State<MirrorGenerationScreen> createState() => _MirrorGenerationScreenState();
}

class _MirrorGenerationScreenState extends State<MirrorGenerationScreen> {
  late final MirrorTryOnController controller =
      widget.controller ?? MirrorTryOnController.current;
  bool _handled = false;
  bool english = false;
  String t(String fr, String en) => english ? en : fr;

  @override
  void initState() {
    super.initState();
    controller.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = controller.state;
      if (state == MirrorTryOnState.photoPreview ||
          state == MirrorTryOnState.camera ||
          state == MirrorTryOnState.selectingOutfit) {
        controller.generate();
      }
      if (mounted) _changed();
    });
  }

  void _changed() {
    if (!mounted) return;
    final state = controller.state;
    if (state == MirrorTryOnState.result && !_handled) {
      _handled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || controller.state != MirrorTryOnState.result) return;
        Navigator.of(context).pushReplacementNamed('/mirror/result');
      });
      return;
    }
    if (state == MirrorTryOnState.error &&
        controller.error?.backToOutfits == true &&
        !_handled) {
      _handled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        controller.loadContent(forceRefresh: true);
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/mirror/catalogues', (route) => false);
      });
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_changed);
    super.dispose();
  }

  void _tryAnotherOutfit() {
    controller.tryAnotherOutfit();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/mirror/catalogues', (route) => false);
  }

  void _returnHome() {
    controller.returnHome();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/mirror/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final photo = controller.capturedPhoto;
    if (photo == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final generating =
        controller.state == MirrorTryOnState.generating ||
        controller.state == MirrorTryOnState.photoPreview;
    return PopScope(
      canPop: !generating,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || generating) return;
        _returnHome();
      },
      child: FullPhotoScene(
        bytes: photo,
        generation: true,
        photoKey: const ValueKey('mirror-generation-photo'),
        english: english,
        onLanguage: () => setState(() => english = !english),
        onBack: generating ? () {} : () => Navigator.maybePop(context),
        body: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              t('Création de votre essayage ✨', 'Creating your try-on ✨'),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontFamilyFallback: ['serif'],
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (MediaQuery.sizeOf(context).height > 650)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  t(
                    'Notre IA prépare votre nouvelle tenue.',
                    'Our AI is preparing your new outfit.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: MediaQuery.sizeOf(context).width - 64,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (generating) ...[
                          SizedBox(
                            width: 90,
                            height: 90,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ShaderMask(
                                  shaderCallback: digiGradient.createShader,
                                  child: const SizedBox(
                                    width: 82,
                                    height: 82,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 5,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.auto_awesome,
                                  color: Color(0xffd795ff),
                                  size: 30,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Création de l’image…',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Cela peut prendre quelques secondes.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ] else ...[
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 56,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            controller.error?.message ?? Friendly.generation,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        footer: generating
            ? OverlayGlass(
                child: Row(
                  children: [
                    const Icon(Icons.checkroom, color: Color(0xffd795ff)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        controller.selectedOutfit?.name ??
                            t('Votre tenue', 'Your outfit'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t('Espace partenaire', 'Partner space'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            : _errorFooter(),
      ),
    );
  }

  Widget _errorFooter() {
    final failure = controller.error;
    if (failure == null) return const SizedBox.shrink();
    return OverlayGlass(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure.backToOutfits) ...[
            const Text(
              'Choisissez une autre tenue pour continuer.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            DigiButton(
              key: const ValueKey('mirror-change-outfit'),
              label: 'Changer de tenue',
              onPressed: _tryAnotherOutfit,
            ),
          ] else ...[
            if (failure.retryable) ...[
              DigiButton(
                key: const ValueKey('mirror-retry'),
                label: 'Réessayer',
                onPressed: () => controller.retryGeneration(),
              ),
              const SizedBox(height: 8),
            ],
            if (!failure.retryable) const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white38),
              ),
              child: TextButton(
                key: const ValueKey('mirror-change-outfit-2'),
                onPressed: _tryAnotherOutfit,
                style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                child: Text(
                  'Changer de tenue',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ],
          TextButton(
            key: const ValueKey('mirror-error-home'),
            onPressed: _returnHome,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Retour à l’accueil',
              style: TextStyle(color: Color(0xffc7d5f7), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
