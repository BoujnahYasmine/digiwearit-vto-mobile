import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The public customer's details, kept only on this phone (encrypted
/// storage) so later try-ons don't ask for them again.
class CustomerProfile extends ChangeNotifier {
  CustomerProfile({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static CustomerProfile instance = CustomerProfile();
  static const _key = 'digiwearit_customer_profile';

  final FlutterSecureStorage _storage;
  bool _loaded = false;
  String name = '';
  String email = '';

  /// The satisfaction survey is shown once, after the first try-on.
  bool rated = false;
  int tryOns = 0;

  /// New-outfit notifications: null until first asked, then the choice.
  bool? notifications;

  bool get hasDetails => name.isNotEmpty || email.isNotEmpty;

  Future<CustomerProfile> load() async {
    if (_loaded) return this;
    _loaded = true;
    try {
      final raw = await _storage.read(key: _key);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        name = data['name'] as String? ?? '';
        email = data['email'] as String? ?? '';
        rated = data['rated'] == true;
        tryOns = data['tryOns'] as int? ?? 0;
        notifications = data['notifications'] as bool?;
      }
    } catch (_) {
      // Unavailable storage: keep this session's values in memory only.
    }
    notifyListeners();
    return this;
  }

  Future<void> _save() async {
    notifyListeners();
    try {
      await _storage.write(
        key: _key,
        value: jsonEncode({
          'name': name,
          'email': email,
          'rated': rated,
          'tryOns': tryOns,
          'notifications': notifications,
        }),
      );
    } catch (_) {}
  }

  Future<void> update({String? name, String? email}) async {
    await load();
    if (name != null) this.name = name.trim();
    if (email != null) this.email = email.trim();
    await _save();
  }

  Future<void> setNotifications(bool on) async {
    await load();
    notifications = on;
    await _save();
  }

  Future<void> markRated() async {
    await load();
    rated = true;
    await _save();
  }

  Future<void> countTryOn() async {
    await load();
    tryOns++;
    await _save();
  }

  /// Forgets the details but keeps the survey answered.
  Future<void> clear() async {
    await load();
    name = '';
    email = '';
    await _save();
  }
}
