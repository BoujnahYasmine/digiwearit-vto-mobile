import 'package:flutter/foundation.dart';

/// Shared, in-memory access state. Never persisted across logins.
class MirrorAccessState extends ChangeNotifier {
  static final shared = MirrorAccessState();
  bool allowed = false;
  bool checking = false;
  Object? error;
  int _version = 0;

  void reset() {
    _version++;
    allowed = false;
    checking = false;
    error = null;
    notifyListeners();
  }

  Future<void> check(Future<void> Function() verify) async {
    if (checking) return;
    final version = _version;
    checking = true;
    notifyListeners();
    try {
      await verify();
      if (version != _version) return;
      allowed = true;
      error = null;
    } catch (failure) {
      if (version != _version) return;
      allowed = false;
      error = failure;
    } finally {
      if (version == _version) {
        checking = false;
        notifyListeners();
      }
    }
  }
}
