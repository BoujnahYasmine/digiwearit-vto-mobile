import 'package:flutter/material.dart';

import '../mobile_layout.dart';
import 'mirror_backend.dart';
import 'mirror_session_service.dart';
import 'mirror_tryon_controller.dart';

/// Mirror authentication gate. Restores any persisted session silently;
/// otherwise asks the operator for the mirror access token.
class MirrorSetupScreen extends StatefulWidget {
  const MirrorSetupScreen({
    super.key,
    this.controller,
    this.ensureReady,
    this.authenticator,
  });
  final MirrorTryOnController? controller;
  final Future<void> Function()? ensureReady;
  final Future<MirrorSession> Function(String token)? authenticator;
  @override
  State<MirrorSetupScreen> createState() => _MirrorSetupScreenState();
}

class _MirrorSetupScreenState extends State<MirrorSetupScreen> {
  late final MirrorTryOnController controller =
      widget.controller ?? MirrorTryOnController.current;
  final _token = TextEditingController();
  bool _connecting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _enter());
  }

  Future<void> _enter() async {
    if (!mounted || _connecting) return;
    setState(() => _connecting = true);
    try {
      await (widget.ensureReady ?? MirrorBackend.ensureReady)();
      if (!mounted) return;
      final ok = await controller.loadContent();
      if (!mounted) return;
      if (ok) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/mirror/universe', (route) => false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Connexion impossible. Veuillez réessayer.');
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _connect() async {
    final token = _token.text.trim();
    if (token.isEmpty || _connecting) return;
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      await (widget.ensureReady ?? MirrorBackend.ensureReady)();
      final authenticate =
          widget.authenticator ??
          ((value) =>
              MirrorSessionService.instance.authenticate(value, persist: true));
      await authenticate(token);
      if (!mounted) return;
      _token.clear();
      final ok = await controller.loadContent(forceRefresh: true);
      if (!mounted) return;
      if (ok) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/mirror/universe', (route) => false);
      } else {
        setState(
          () => _error = controller.contentError ?? 'Chargement impossible.',
        );
      }
    } on MirrorSessionException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Connexion impossible.');
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xff11101b),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: digiGradient,
                    ),
                    child: Image.asset('lib/logo digiwearit.png'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Espace partenaire',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Entrez le code d’activation fourni par Digiwearit pour activer cet appareil.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xffb9aed0),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xff1d1733),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          key: const ValueKey('mirror-token-field'),
                          controller: _token,
                          enabled: !_connecting,
                          obscureText: true,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _connecting ? null : _connect(),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Code d’activation',
                            hintStyle: const TextStyle(
                              color: Color(0xff8f84a8),
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Color(0xff8f84a8),
                            ),
                            filled: true,
                            fillColor: const Color(0xff221a3e),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xffff8fa3),
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: DigiButton(
                            key: const ValueKey('mirror-connect'),
                            label: _connecting
                                ? 'Connexion…'
                                : 'Activer cet appareil',
                            onPressed: _connecting ? null : _connect,
                          ),
                        ),
                        if (_connecting)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Retour',
                      style: TextStyle(color: Color(0xffc7d5f7), fontSize: 13),
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
