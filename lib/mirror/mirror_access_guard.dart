import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../experience_failure.dart';
import 'mirror_backend.dart';
import 'mirror_access_state.dart';

/// Rechecks active partner routes, including routes with already cached content.
class MirrorAccessGuard extends StatefulWidget {
  const MirrorAccessGuard({
    super.key,
    required this.child,
    this.verifyAccess,
    this.accessState,
  });
  final Widget child;
  final MirrorAccessState? accessState;
  final Future<void> Function()? verifyAccess;
  @override
  State<MirrorAccessGuard> createState() => _MirrorAccessGuardState();
}

class _MirrorAccessGuardState extends State<MirrorAccessGuard>
    with WidgetsBindingObserver {
  Timer? _timer;
  late final MirrorAccessState _access =
      widget.accessState ??
      (widget.verifyAccess == null
          ? MirrorAccessState.shared
          : MirrorAccessState());
  bool get _checking => _access.checking;
  bool get _allowed => _access.allowed;
  String _message = "Vérification de l'accès partenaire...";
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _access.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _check();
    });
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _check());
  }

  void _changed() {
    if (!mounted) return;
    final error = _access.error;
    if (error is FirebaseFunctionsException) {
      final reason = error.details is Map
          ? (error.details as Map)['reason']
          : null;
      _message =
          reason == 'ENTERPRISE_SUSPENDED' || reason == 'MIRROR_SUSPENDED'
          ? Friendly.servicePaused
          : error.code == 'unauthenticated'
          ? Friendly.mirrorReconnect
          : Friendly.generic;
    } else if (error != null) {
      _message = Friendly.connection;
    }
    setState(() {});
  }

  Future<void> _check() => _access.check(() async {
    if (widget.verifyAccess != null) {
      await widget.verifyAccess!();
    } else {
      await MirrorBackend.ensureReady();
      await MirrorBackend.functions
          .httpsCallable(
            'checkMirrorAccess',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
          )
          .call<void>();
    }
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _check();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _access.removeListener(_changed);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _allowed
      ? widget.child
      : Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _checking
                        ? "Vérification de l?accès partenaire..."
                        : _message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _checking ? null : _check,
                    child: const Text('Reessayer'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (_) => false),
                    child: const Text('Retour a l\'accueil'),
                  ),
                ],
              ),
            ),
          ),
        );
}
