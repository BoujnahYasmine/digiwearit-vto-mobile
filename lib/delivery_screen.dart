import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'experience_session.dart';
import 'experience_failure.dart';
import 'mobile_layout.dart';

Future<bool?> showDeliverySheet(
  BuildContext context, {
  required Uint8List bytes,
  required String resultId,
  Future<void> Function(String, Uint8List, String)? sender,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  barrierColor: const Color(0x59080619),
  builder: (context) =>
      DeliverySheet(bytes: bytes, resultId: resultId, sender: sender),
);

class DeliverySheet extends StatefulWidget {
  const DeliverySheet({
    super.key,
    required this.bytes,
    required this.resultId,
    this.sender,
  });
  final Uint8List bytes;
  final String resultId;
  final Future<void> Function(String, Uint8List, String)? sender;
  @override
  State<DeliverySheet> createState() => _DeliverySheetState();
}

class _DeliverySheetState extends State<DeliverySheet> {
  final email = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false, sent = false;
  String? error;
  bool get available => ExperienceApi.configured || widget.sender != null;
  bool get validEmail =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.text.trim());
  @override
  void dispose() {
    email.clear();
    email.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (busy || !available || !validEmail || !form.currentState!.validate()) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await (widget.sender ?? ExperienceApi.sendPhoto)(
        email.text.trim(),
        widget.bytes,
        widget.resultId,
      );
      if (mounted) setState(() => sent = true);
    } catch (e) {
      if (mounted) {
        setState(
          () => error = explainFailure(e, fallback: Friendly.emailNotSent),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final remaining = (media.size.height - keyboard - media.padding.top).clamp(
      0.0,
      media.size.height,
    );
    final height = keyboard > 0 ? remaining * .9 : media.size.height * .58;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xe0231c37),
                border: Border(top: BorderSide(color: Colors.white24)),
              ),
              padding: EdgeInsets.fromLTRB(
                18,
                8,
                18,
                12 + media.padding.bottom,
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 34,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Container(
                          width: 42,
                          height: 4,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Colors.white54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            tooltip: 'Fermer',
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white12,
                            ),
                            onPressed: busy
                                ? null
                                : () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) => Center(
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: SizedBox(
                            width: box.maxWidth,
                            child: Form(
                              key: form,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (keyboard == 0 || sent) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xffb9c8ff),
                                            Color(0xffedb3ee),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0x668245f6),
                                            blurRadius: 18,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        sent ? Icons.check : Icons.mail_outline,
                                        color: digiInk,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  Text(
                                    sent
                                        ? 'Photo envoyée !'
                                        : 'Recevoir mon essayage',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 23,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (sent)
                                    const Text(
                                      'Votre essayage a été envoyé à votre adresse e-mail.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    )
                                  else ...[
                                    if (keyboard == 0) ...[
                                      const Text(
                                        'Entrez votre adresse e-mail pour recevoir votre photo. Adresse visible par Digiwearit et votre entreprise partenaire.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                    ],
                                    TextFormField(
                                      controller: email,
                                      enabled: available && !busy,
                                      keyboardType: TextInputType.emailAddress,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      textInputAction: TextInputAction.send,
                                      autocorrect: false,
                                      onChanged: (_) => setState(() {}),
                                      onFieldSubmitted: (_) => send(),
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Adresse e-mail',
                                        hintText: 'votre@email.com',
                                        labelStyle: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                        hintStyle: const TextStyle(
                                          color: Colors.white38,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.mail_outline,
                                          color: Colors.white70,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white10,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 16,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.white38,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.white38,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xffb887fa),
                                            width: 2,
                                          ),
                                        ),
                                        errorStyle: const TextStyle(
                                          color: Color(0xffffc4d8),
                                        ),
                                        errorMaxLines: 2,
                                      ),
                                      validator: (_) => validEmail
                                          ? null
                                          : 'Veuillez saisir une adresse e-mail valide.',
                                    ),
                                    if (!available)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 10),
                                        child: Text(
                                          'ⓘ Fonction d’envoi bientôt disponible.',
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    if (error != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Text(
                                          error!,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xffffc4d8),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      DigiButton(
                        key: const ValueKey('email-action'),
                        label: sent
                            ? 'Continuer'
                            : busy
                            ? 'Envoi en cours…'
                            : error != null
                            ? 'Réessayer l’envoi'
                            : '✉ Envoyer ma photo',
                        onPressed: busy
                            ? null
                            : sent
                            ? () => Navigator.pop(context, true)
                            : available && validEmail
                            ? send
                            : null,
                      ),
                      if (busy)
                        const Positioned(
                          left: 12,
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
