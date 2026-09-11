import 'package:flutter/material.dart';
import 'demo_payment_dialog.dart';
import 'experience_failure.dart';
import 'experience_session.dart';
import 'generation_view.dart';
import 'result_screen.dart';
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
  @override
  void initState() {
    super.initState();
    session.addListener(changed);
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
    final outcome = await showDemoPayment(
      context,
      onProcessing: () => session.setPayment(PaymentStatus.processing),
    );
    paying = false;
    if (!mounted) return;
    if (outcome == 'paid') {
      paymentError = null;
      session.setPayment(PaymentStatus.demoPaid);
    }
    if (outcome == 'failed') {
      paymentError = 'Le paiement simulé a été refusé.';
      session.setPayment(PaymentStatus.failed);
    }
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
      covered: session.covered,
      paid: session.payment == PaymentStatus.demoPaid || session.covered,
      error: session.error == null ? null : explainFailure(session.error!),
      paymentError: paymentError,
      onPay: pay,
      onGenerate: session.generate,
    );
  }
}
