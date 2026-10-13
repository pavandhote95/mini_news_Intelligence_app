import '../../domain/entities/user.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.token,
    required this.loggedInAt,
  });

  factory UserModel.fromMap(Map<dynamic, dynamic> map) => UserModel(
        id: map['id'] as String,
        email: map['email'] as String,
        name: map['name'] as String,
        token: map['token'] as String,
        loggedInAt: DateTime.parse(map['loggedInAt'] as String),
      );

  final String id;
  final String email;
  final String name;

  /// Session token. Mocked locally today; a real backend would issue it.
  final String token;
  final DateTime loggedInAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'name': name,
        'token': token,
        'loggedInAt': loggedInAt.toIso8601String(),
      };

  User toEntity() => User(id: id, email: email, name: name, loggedInAt: loggedInAt);
}
