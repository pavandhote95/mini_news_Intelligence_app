import '../../../../core/utils/result.dart';
import '../entities/user.dart';

abstract interface class AuthRepository {
  /// The persisted session, read synchronously at startup so the router can
  /// decide the first screen without a splash delay.
  User? getCurrentUser();

  Future<Result<User>> login({required String email, required String password});

  Future<Result<void>> logout();
}
