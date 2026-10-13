import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/validators.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUser {
  const GetCurrentUser(this._repository);
  final AuthRepository _repository;

  User? call() => _repository.getCurrentUser();
}

class Login {
  const Login(this._repository);
  final AuthRepository _repository;

  /// Validation lives in the domain so it applies no matter which UI calls it.
  Future<Result<User>> call({required String email, required String password}) async {
    final error = Validators.email(email) ?? Validators.password(password);
    if (error != null) return Err(ValidationFailure(error));
    return _repository.login(email: email.trim().toLowerCase(), password: password);
  }
}

class Logout {
  const Logout(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.logout();
}
