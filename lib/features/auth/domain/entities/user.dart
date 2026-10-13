import 'package:flutter/foundation.dart';

@immutable
class User {
  const User({required this.id, required this.email, required this.name, required this.loggedInAt});

  final String id;
  final String email;
  final String name;
  final DateTime loggedInAt;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  bool operator ==(Object other) => other is User && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);
}
