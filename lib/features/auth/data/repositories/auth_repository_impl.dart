import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../models/user_model.dart';

/// Local "simple login".
///
/// Public news APIs have no user accounts, so credentials are validated
/// locally and a session is created and persisted in Hive. Swapping in a
/// real backend only requires a remote data source here — nothing above the
/// repository changes.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._local, {this.simulatedLatency = const Duration(milliseconds: 700)});

  final AuthLocalDataSource _local;
  final Duration simulatedLatency;

  @override
  User? getCurrentUser() => _local.getSession()?.toEntity();

  @override
  Future<Result<User>> login({required String email, required String password}) async {
    try {
      await Future<void>.delayed(simulatedLatency);
      final now = DateTime.now();
      final model = UserModel(
        id: _stableId(email),
        email: email,
        name: _nameFromEmail(email),
        token: 'local-${now.microsecondsSinceEpoch}',
        loggedInAt: now,
      );
      await _local.saveSession(model);
      return Success(model.toEntity());
    } catch (e, st) {
      return Err(ErrorMapper.map(e, st));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _local.clearSession();
      return const Success(null);
    } catch (e, st) {
      return Err(ErrorMapper.map(e, st));
    }
  }

  /// Deterministic id per email (String.hashCode is not stable across runs).
  static String _stableId(String email) {
    final hash = email.codeUnits.fold<int>(17, (h, c) => (h * 31 + c) & 0x7fffffff);
    return 'u_${hash.toRadixString(16)}';
  }

  /// "jane.doe@acme.com" -> "Jane Doe"
  static String _nameFromEmail(String email) {
    final local = email.split('@').first;
    final words = local.split(RegExp(r'[._\-+]+')).where((w) => w.isNotEmpty);
    final name = words.map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    return name.isEmpty ? 'Reader' : name;
  }
}
