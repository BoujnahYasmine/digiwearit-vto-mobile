import 'mobile_layout.dart';
import 'experience_failure.dart';
import 'package:flutter/material.dart';
import 'experience_session.dart';

class PartnerScreen extends StatefulWidget {
  const PartnerScreen({super.key, this.english = false});
  final bool english;
  @override
  State<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends State<PartnerScreen> {
  final token = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    token.clear();
    token.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (token.text.trim().isEmpty) {
      setState(() => error = 'Entrez votre token professionnel.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ExperienceSession.authenticate(token.text.trim());
      token.clear();
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/universe',
          arguments: widget.english,
        );
      }
    } catch (failure) {
      if (mounted) {
        setState(
          () => error = explainFailure(
            failure,
            fallback:
                'Connexion impossible. Vérifiez votre token et votre abonnement.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => DigiScaffold(
    header: DigiHeader(onBack: () => Navigator.maybePop(context)),
    title: 'Connectez votre boutique',
    body: SingleChildScrollView(
      child: DigiGlass(
        child: Column(
          children: [
            const Text(
              'Votre abonnement prend en charge les essayages après validation de votre compte.',
            ),
            const SizedBox(height: 20),
            TextField(
              controller: token,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Token professionnel',
                border: OutlineInputBorder(),
              ),
            ),
            if (!ExperienceApi.configured)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'La connexion partenaire sera disponible après activation du service.',
                ),
              ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(error!),
              ),
          ],
        ),
      ),
    ),
    footer: DigiButton(
      label: busy ? 'Connexion…' : 'Se connecter',
      onPressed: busy || !ExperienceApi.configured ? null : submit,
    ),
  );
}
