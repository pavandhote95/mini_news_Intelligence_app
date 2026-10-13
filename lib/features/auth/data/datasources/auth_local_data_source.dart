import 'package:hive/hive.dart';

import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

/// Persists the logged-in session in Hive so it survives app restarts.
class AuthLocalDataSource {
  AuthLocalDataSource(this._box);

  final Box<dynamic> _box;
  static const String _sessionKey = 'session';

  UserModel? getSession() {
    final raw = _box.get(_sessionKey);
    if (raw is! Map) return null;
    try {
      return UserModel.fromMap(raw);
    } catch (_) {
      // Corrupt or outdated session: treat as logged out.
      return null;
    }
  }

  Future<void> saveSession(UserModel user) async {
    try {
      await _box.put(_sessionKey, user.toMap());
    } catch (e) {
      throw CacheException('Failed to save session: $e');
    }
  }

  Future<void> clearSession() async {
    try {
      await _box.delete(_sessionKey);
    } catch (e) {
      throw CacheException('Failed to clear session: $e');
    }
  }
}
