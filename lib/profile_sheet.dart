import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'customer_profile.dart';
import 'mobile_layout.dart';
import 'history_view.dart';
import 'support_sheet.dart';
import 'try_on_history.dart';
import 'outfit_notifications.dart';

Future<void> showProfileSheet(
  BuildContext context, {
  CustomerProfile? profile,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  barrierColor: const Color(0x59080619),
  builder: (_) => ProfileSheet(profile: profile ?? CustomerProfile.instance),
);

/// The customer's details saved on this phone: name, e-mail for receiving
/// photos, number of try-ons. Nothing here leaves the device until a photo
/// is sent.
class ProfileSheet extends StatefulWidget {
  const ProfileSheet({super.key, required this.profile});
  final CustomerProfile profile;
  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  final name = TextEditingController();
  final email = TextEditingController();
  final form = GlobalKey<FormState>();
  bool loading = true, saved = false;
  List<TryOnRecord> history = const [];

  Future<void> loadHistory() async {
    final records = await TryOnHistory.instance.records();
    if (mounted) setState(() => history = records);
  }

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  void initState() {
    super.initState();
    loadHistory();
    widget.profile.load().then((p) {
      if (!mounted) return;
      setState(() {
        name.text = p.name;
        email.text = p.email;
        loading = false;
      });
    });
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await widget.profile.update(name: name.text, email: email.text);
    if (mounted) setState(() => saved = true);
  }

  Future<void> forget() async {
    await widget.profile.clear();
    await TryOnHistory.instance.clear();
    history = const [];
    if (!mounted) return;
    setState(() {
      name.clear();
      email.clear();
      saved = false;
    });
  }

  InputDecoration _field(String label, IconData icon, String hint) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white38),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xffb887fa), width: 2),
        ),
        errorStyle: const TextStyle(color: Color(0xffffc4d8)),
      );

  Widget _info(IconData icon, String title, String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white24),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xffd2b8ff), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final p = widget.profile;
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            constraints: BoxConstraints(maxHeight: media.size.height * .9),
            decoration: const BoxDecoration(
              color: Color(0xe8231c37),
              border: Border(top: BorderSide(color: Colors.white24)),
            ),
            padding: EdgeInsets.fromLTRB(18, 8, 18, 14 + media.padding.bottom),
            child: loading
                ? const SizedBox(
                    height: 200,
                    child: Center(child: DigiSpinner(size: 48)),
                  )
                : SingleChildScrollView(
                    child: Form(
                      key: form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 40),
                              Expanded(
                                child: Center(
                                  child: Container(
                                    width: 42,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.white54,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Fermer',
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white12,
                                ),
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: digiGradient,
                            ),
                            alignment: Alignment.center,
                            child: p.name.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 34,
                                  )
                                : Text(
                                    p.name.characters.first.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            p.name.isEmpty ? 'Mon profil' : 'Bonjour ${p.name}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Vos informations restent sur ce téléphone et '
                            'sont remplies automatiquement à chaque essayage.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const ValueKey('profile-name'),
                            controller: name,
                            textCapitalization: TextCapitalization.words,
                            maxLength: 40,
                            onChanged: (_) => setState(() => saved = false),
                            style: const TextStyle(color: Colors.white),
                            decoration: _field(
                              'Prénom',
                              Icons.person_outline,
                              'Votre prénom',
                            ).copyWith(counterText: ''),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            key: const ValueKey('profile-email'),
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            onChanged: (_) => setState(() => saved = false),
                            style: const TextStyle(color: Colors.white),
                            decoration: _field(
                              'Adresse e-mail',
                              Icons.mail_outline,
                              'votre@email.com',
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              return text.isEmpty || _email.hasMatch(text)
                                  ? null
                                  : 'Veuillez saisir une adresse e-mail valide.';
                            },
                          ),
                          const SizedBox(height: 12),
                          DigiButton(
                            key: const ValueKey('profile-save'),
                            label: saved ? '✓ Enregistré' : 'Enregistrer',
                            onPressed: save,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Icon(
                                Icons.photo_library_outlined,
                                color: Color(0xffd2b8ff),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                history.isEmpty
                                    ? 'Mes essayages'
                                    : 'Mes essayages (${history.length})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          HistoryGrid(records: history, onChanged: loadHistory),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            key: const ValueKey('profile-support'),
                            onPressed: () => showSupportSheet(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            icon: const Icon(Icons.support_agent),
                            label: const Text(
                              'Contacter le support · remboursement',
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (OutfitNotifications.supported) ...[
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: SwitchListTile(
                                key: const ValueKey('profile-notifications'),
                                value: p.notifications ?? false,
                                activeThumbColor: const Color(0xffd2b8ff),
                                secondary: const Icon(
                                  Icons.notifications_active_outlined,
                                  color: Color(0xffd2b8ff),
                                ),
                                title: const Text(
                                  'Nouvelles tenues',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Être prévenu(e) quand une tenue arrive.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                onChanged: (on) async {
                                  await p.setNotifications(on);
                                  setState(() {});
                                  await OutfitNotifications.instance.enable(on);
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          _info(
                            Icons.credit_card,
                            'Paiement',
                            'Le paiement passe par Google Play : votre carte '
                                'reste enregistrée dans votre compte Google, '
                                'vous n’avez pas à la ressaisir.',
                          ),
                          if (p.hasDetails || history.isNotEmpty)
                            TextButton(
                              onPressed: forget,
                              child: const Text(
                                'Effacer mes informations et mes photos',
                                style: TextStyle(color: Color(0xffffbdd4)),
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
}
