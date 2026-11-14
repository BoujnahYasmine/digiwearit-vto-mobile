import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'customer_profile.dart';
import 'mobile_layout.dart';
import 'try_on_history.dart';

const supportEmail = 'hi@digiwearit.com';

enum SupportReason {
  failedTryOn('Essayage raté', Icons.auto_awesome),
  refund('Demande de remboursement', Icons.payments_outlined),
  appProblem('Problème dans l’application', Icons.bug_report_outlined),
  other('Autre question', Icons.chat_bubble_outline);

  const SupportReason(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// The support e-mail (to Digiwearit) with the reason and try-on reference
/// filled in, so the team can find the try-on and refund it if needed.
Uri supportMail({
  required SupportReason reason,
  String message = '',
  TryOnRecord? tryOn,
  String name = '',
  String email = '',
}) {
  String two(int n) => n.toString().padLeft(2, '0');
  final lines = [
    'Motif : ${reason.label}',
    if (tryOn != null) ...[
      'Essayage : ${tryOn.outfit}',
      'Référence : ${tryOn.id}',
      'Date : ${two(tryOn.date.day)}/${two(tryOn.date.month)}/'
          '${tryOn.date.year} ${two(tryOn.date.hour)}:${two(tryOn.date.minute)}',
    ],
    if (name.isNotEmpty) 'Nom : $name',
    if (email.isNotEmpty) 'E-mail : $email',
    '',
    message.trim().isEmpty ? 'Décrivez votre problème ici :' : message.trim(),
  ];
  return Uri(
    scheme: 'mailto',
    path: supportEmail,
    query: [
      'subject=${Uri.encodeComponent('Support Digiwearit – ${reason.label}')}',
      'body=${Uri.encodeComponent(lines.join('\n'))}',
    ].join('&'),
  );
}

Future<void> showSupportSheet(BuildContext context, {TryOnRecord? tryOn}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x59080619),
      builder: (_) => SupportSheet(tryOn: tryOn),
    );

class SupportSheet extends StatefulWidget {
  const SupportSheet({super.key, this.tryOn, this.launcher});
  final TryOnRecord? tryOn;
  final Future<bool> Function(Uri)? launcher;
  @override
  State<SupportSheet> createState() => _SupportSheetState();
}

class _SupportSheetState extends State<SupportSheet> {
  late SupportReason reason = widget.tryOn == null
      ? SupportReason.appProblem
      : SupportReason.failedTryOn;
  final message = TextEditingController();
  String? error;

  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final profile = await CustomerProfile.instance.load();
    final uri = supportMail(
      reason: reason,
      message: message.text,
      tryOn: widget.tryOn,
      name: profile.name,
      email: profile.email,
    );
    var opened = false;
    try {
      opened =
          await (widget.launcher ??
              (u) => launchUrl(u, mode: LaunchMode.externalApplication))(uri);
    } catch (_) {}
    if (!mounted) return;
    if (opened) {
      Navigator.pop(context);
    } else {
      setState(
        () => error =
            'Aucune application e-mail trouvée. Écrivez-nous à $supportEmail.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            constraints: BoxConstraints(maxHeight: media.size.height * .9),
            decoration: const BoxDecoration(
              color: Color(0xf0231c37),
              border: Border(top: BorderSide(color: Colors.white24)),
            ),
            padding: EdgeInsets.fromLTRB(18, 8, 18, 14 + media.padding.bottom),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Fermer',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white12,
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                  const Icon(
                    Icons.support_agent,
                    color: Color(0xffd2b8ff),
                    size: 44,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Contacter le support',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.tryOn == null
                        ? 'Un souci avec un essayage ou l’application ? '
                              'Notre équipe vous répond par e-mail.'
                        : 'Essayage « ${widget.tryOn!.outfit} » : sa référence '
                              'est ajoutée à votre message.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  for (final option in SupportReason.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: option == reason
                            ? const Color(0x558245f6)
                            : Colors.white.withValues(alpha: .06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: option == reason
                                ? const Color(0xffb887fa)
                                : Colors.white24,
                          ),
                        ),
                        child: ListTile(
                          key: ValueKey('support-${option.name}'),
                          dense: true,
                          leading: Icon(option.icon, color: Colors.white),
                          title: Text(
                            option.label,
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: option == reason
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xffd2b8ff),
                                )
                              : null,
                          onTap: () => setState(() => reason = option),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: message,
                    maxLines: 4,
                    minLines: 3,
                    maxLength: 500,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Décrivez le problème (facultatif)',
                      hintStyle: const TextStyle(color: Colors.white38),
                      counterStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white10,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white38),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xffb887fa),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xffffc4d8)),
                      ),
                    ),
                  DigiButton(
                    key: const ValueKey('support-send'),
                    label: '✉ Écrire au support',
                    onPressed: send,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Votre application e-mail s’ouvre avec le message prêt, '
                    'adressé à $supportEmail.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 11),
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
