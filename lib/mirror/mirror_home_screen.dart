import 'package:flutter/material.dart';

import '../mobile_layout.dart';
import 'mirror_session_service.dart';
import 'mirror_tryon_controller.dart';

/// Standby home: the customer try-on state is empty here; mirror
/// authentication and enterprise content persist across customer activities.
class MirrorHomeScreen extends StatefulWidget {
  const MirrorHomeScreen({super.key, this.controller});
  final MirrorTryOnController? controller;
  @override
  State<MirrorHomeScreen> createState() => _MirrorHomeScreenState();
}

class _MirrorHomeScreenState extends State<MirrorHomeScreen> {
  late final MirrorTryOnController controller =
      widget.controller ?? MirrorTryOnController.current;

  @override
  void initState() {
    super.initState();
    controller.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_changed);
    super.dispose();
  }

  Future<void> _start() async {
    if (controller.content == null) {
      final ok = await controller.loadContent();
      if (!ok || !mounted) return;
    }
    if (!mounted) return;
    Navigator.of(context).pushNamed('/mirror/catalogues');
  }

  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text(
          'Fermer l’espace partenaire et effacer la session ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await MirrorSessionService.instance.signOut();
    controller.returnHome();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/mirror', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final content = controller.content;
    return Scaffold(
      backgroundColor: const Color(0xff11101b),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: digiGradient,
                    ),
                    child: content?.logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.network(
                              content!.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.checkroom,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.checkroom,
                            color: Colors.white,
                            size: 40,
                          ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    content?.enterpriseName ?? 'Espace partenaire',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Essayez des tenues en temps réel',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xffb9aed0), fontSize: 14),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: DigiButton(
                      key: const ValueKey('mirror-home-start'),
                      label: 'Commencer un essayage',
                      onPressed: _start,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    key: const ValueKey('mirror-home-logout'),
                    onPressed: _logout,
                    icon: const Icon(
                      Icons.logout,
                      color: Color(0xffc7d5f7),
                      size: 16,
                    ),
                    label: const Text(
                      'Se déconnecter',
                      style: TextStyle(color: Color(0xffc7d5f7), fontSize: 12),
                    ),
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
