import 'package:flutter/material.dart';
import 'demo_payment_dialog.dart';
import 'experience_failure.dart';
import 'generation_view.dart';
import 'result_screen.dart';
import 'store_payment.dart';
import 'try_on_session.dart';

class GenerationScreen extends StatefulWidget {
  const GenerationScreen({super.key});
  @override
  State<GenerationScreen> createState() => _GenerationScreenState();
}

class _GenerationScreenState extends State<GenerationScreen> {
  final session = TryOnSession.current;
  bool paying = false, revealed = false;
  String? paymentError;
  String price = '29 DH';
  @override
  void initState() {
    super.initState();
    session.addListener(changed);
    if (StorePayment.supported)
      StorePayment.instance.load().then((product) {
        if (product != null && mounted) setState(() => price = product.price);
      });
    if (session.capturedPhoto != null) session.generate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) changed();
    });
  }

  void changed() {
    if (!mounted) return;
    setState(() {});
    if (session.canReveal && !revealed) {
      revealed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !session.canReveal) return;
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ResultScreen(
              images: session.results,
              outfitName: session.outfit!.name,
              resultId: session.requestId!,
              selection: session.selection!,
            ),
          ),
        );
      });
    }
  }

  Future<void> pay() async {
    if (paying) return;
    paying = true;
    final outcome = StorePayment.supported
        ? await storePay()
        : await showDemoPayment(
            context,
            onProcessing: () => session.setPayment(PaymentStatus.processing),
          );
    paying = false;
    if (!mounted) return;
    if (outcome == 'paid') {
      paymentError = null;
      session.setPayment(PaymentStatus.paid);
    } else if (outcome == 'failed') {
      paymentError = Friendly.paymentFailed;
      session.setPayment(PaymentStatus.failed);
    } else if (outcome == 'unavailable') {
      paymentError = Friendly.paymentUnavailable;
      session.setPayment(PaymentStatus.failed);
    } else if (session.payment == PaymentStatus.processing) {
      session.setPayment(PaymentStatus.pending);
    }
  }

  /// Opens the Google Play / App Store payment sheet; null when cancelled.
  Future<String?> storePay() async {
    session.setPayment(PaymentStatus.processing);
    return switch (await StorePayment.instance.buy()) {
      StorePaymentOutcome.paid => 'paid',
      StorePaymentOutcome.failed => 'failed',
      StorePaymentOutcome.unavailable => 'unavailable',
      StorePaymentOutcome.cancelled => null,
    };
  }

  @override
  void dispose() {
    session.removeListener(changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outfit = session.outfit, photo = session.capturedPhoto;
    if (outfit == null || photo == null)
      return const Scaffold(
        body: Center(child: Text('Choisissez une tenue et prenez une photo.')),
      );
    return GenerationView(
      photo: photo,
      outfitName: outfit.name,
      outfitUrl: outfit.fullImageUrl,
      busy: session.status == TryOnStatus.processing,
      stage: 1,
      generated: session.status == TryOnStatus.completed,
      paid: session.payment == PaymentStatus.paid,
      error: session.error == null
          ? null
          : explainFailure(session.error!, fallback: Friendly.generation),
      paymentError: paymentError,
      price: price,
      demo: !StorePayment.supported,
      onPay: session.payment == PaymentStatus.processing ? null : pay,
      onGenerate: session.generate,
    );
  }
}
