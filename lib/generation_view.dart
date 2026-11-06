import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'mobile_layout.dart';
import 'full_photo_scene.dart';

class GenerationView extends StatefulWidget {
  const GenerationView({
    super.key,
    required this.photo,
    required this.outfitName,
    required this.outfitUrl,
    required this.busy,
    required this.stage,
    required this.onGenerate,
    this.result,
    this.error,
    this.checkout = false,
    this.paid = false,
    this.generated = false,
    this.onPay,
    this.paymentError,
    this.price = '29 DH',
    this.demo = true,
  });
  final Uint8List photo;
  final Uint8List? result;
  final String outfitName, outfitUrl, price;
  final bool busy, checkout, paid, generated;

  /// Simulated payment (web/tests); false when paying through the stores.
  final bool demo;
  final int stage;
  final String? error, paymentError;
  final VoidCallback onGenerate;
  final VoidCallback? onPay;
  @override
  State<GenerationView> createState() => _GenerationViewState();
}

class _GenerationViewState extends State<GenerationView> {
  bool english = false;
  String method = 'Carte bancaire';
  String t(String fr, String en) => english ? en : fr;
  String storeName() => defaultTargetPlatform == TargetPlatform.iOS
      ? t('l’App Store', 'the App Store')
      : 'Google Play';
  @override
  Widget build(BuildContext context) => FullPhotoScene(
    bytes: widget.photo,
    generation: true,
    photoKey: const ValueKey('generation-photo'),
    english: english,
    onLanguage: () => setState(() => english = !english),
    onBack: () => Navigator.maybePop(context),
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
        if (MediaQuery.sizeOf(context).height > 650 &&
            MediaQuery.textScalerOf(context).scale(16) < 23)
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
                    if (widget.busy && widget.error == null)
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
                      )
                    else
                      Icon(
                        widget.error != null
                            ? Icons.auto_awesome
                            : Icons.check_circle_outline,
                        color: Colors.white,
                        size: 56,
                      ),
                    const SizedBox(height: 18),
                    Text(
                      widget.error != null
                          ? t(
                              'Encore un petit instant ✨',
                              'Just one more moment ✨',
                            )
                          : widget.generated
                          ? t(
                              'Votre essayage est prêt ! ✨',
                              'Your try-on is ready! ✨',
                            )
                          : widget.stage == 0
                          ? t(
                              'Préparation de votre photo…',
                              'Preparing your photo…',
                            )
                          : t('Création de l’image…', 'Creating the image…'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.error ??
                          (widget.generated && !widget.paid
                              ? t(
                                  'Finalisez le paiement pour le découvrir.',
                                  'Complete payment to reveal it.',
                                )
                              : widget.generated
                              ? t('Essayage prêt', 'Try-on ready')
                              : t(
                                  'Cela peut prendre quelques secondes.',
                                  'This may take a few moments.',
                                )),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    footer: OverlayGlass(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.outfitName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Text(
                widget.price,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 10),
            DigiButton(
              key: const ValueKey('generation-action'),
              label: t('Réessayer', 'Retry'),
              onPressed: widget.busy ? null : widget.onGenerate,
            ),
          ] else if (widget.paid) ...[
            const SizedBox(height: 12),
            Text(
              widget.demo
                  ? t(
                      '✓ Paiement confirmé (démo)',
                      '✓ Payment confirmed (demo)',
                    )
                  : t('✓ Paiement confirmé', '✓ Payment confirmed'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.busy)
              Text(
                t(
                  'Votre essayage est en cours de création.',
                  'Your try-on is being created.',
                ),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
          ] else ...[
            const SizedBox(height: 10),
            // Store builds: the Google Play / App Store sheet picks the card.
            if (widget.demo)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: method,
                    isExpanded: true,
                    dropdownColor: const Color(0xff44384e),
                    iconEnabledColor: Colors.white,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: [
                      for (final name in [
                        'Carte bancaire',
                        'Wallet Maroc',
                        'Inwi Money',
                      ])
                        DropdownMenuItem(
                          value: name,
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => method = value);
                    },
                  ),
                ),
              ),
            if (widget.paymentError != null)
              Text(
                widget.paymentError!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xffffbfd4), fontSize: 12),
              ),
            const SizedBox(height: 12),
            DigiButton(
              key: const ValueKey('demo-pay'),
              label: widget.paymentError != null
                  ? t('Réessayer le paiement', 'Retry payment')
                  : widget.demo
                  ? t(
                      'Payer ${widget.price} · Démo',
                      'Pay ${widget.price} · Demo',
                    )
                  : t(
                      '🔒 Payer ${widget.price} par carte',
                      '🔒 Pay ${widget.price} by card',
                    ),
              onPressed: widget.onPay,
            ),
            const SizedBox(height: 6),
            Text(
              widget.demo
                  ? t('Démo · aucun débit réel.', 'Demo · no actual charge.')
                  : t(
                      'Paiement sécurisé via ${storeName()}.',
                      'Secure payment via ${storeName()}.',
                    ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ],
      ),
    ),
  );
}
