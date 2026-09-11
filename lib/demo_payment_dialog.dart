import 'package:flutter/material.dart';
import 'full_photo_scene.dart';
import 'mobile_layout.dart';

Future<String?> showDemoPayment(
  BuildContext context, {
  VoidCallback? onProcessing,
}) => showDialog<String>(
  context: context,
  barrierColor: const Color(0x59080619),
  builder: (_) => DemoPaymentDialog(onProcessing: onProcessing),
);

class DemoPaymentDialog extends StatefulWidget {
  const DemoPaymentDialog({super.key, this.onProcessing});
  final VoidCallback? onProcessing;
  @override
  State<DemoPaymentDialog> createState() => _DemoPaymentDialogState();
}

class _DemoPaymentDialogState extends State<DemoPaymentDialog> {
  bool processing = false;
  Future<void> confirm() async {
    if (processing) return;
    setState(() => processing = true);
    widget.onProcessing?.call();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) Navigator.pop(context, 'paid');
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !processing,
    child: Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: (MediaQuery.sizeOf(context).width - 32).clamp(0.0, 390.0),
            child: OverlayGlass(
              tint: const Color(0xb8231c37),
              blur: 24,
              borderColor: Colors.white24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      tooltip: 'Fermer',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white12,
                        side: const BorderSide(color: Colors.white24),
                      ),
                      onPressed: processing
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xffd9c9f8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0x888245f6), blurRadius: 20),
                      ],
                    ),
                    child: const Icon(
                      Icons.credit_card,
                      color: digiInk,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Paiement de démonstration',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '29 DH',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Aucun débit réel ne sera effectué.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Confirmez le paiement simulé pour continuer votre essayage.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  DigiButton(
                    key: const ValueKey('confirm-demo-payment'),
                    label: processing
                        ? 'Confirmation…'
                        : '🔒 Confirmer le paiement',
                    onPressed: processing ? null : confirm,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: processing
                        ? null
                        : () => Navigator.pop(context, 'failed'),
                    child: const Text(
                      'Simuler un refus',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  TextButton(
                    onPressed: processing ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
