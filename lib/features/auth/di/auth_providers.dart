import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_boxes.dart';
import '../data/datasources/auth_local_data_source.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/auth_usecases.dart';

/// Dependency graph for the auth feature. Tests override [authRepositoryProvider].
final authBoxProvider = Provider<Box<dynamic>>((ref) => Hive.box<dynamic>(HiveBoxes.auth));

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>(
  (ref) => AuthLocalDataSource(ref.watch(authBoxProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authLocalDataSourceProvider)),
);

final getCurrentUserProvider = Provider((ref) => GetCurrentUser(ref.watch(authRepositoryProvider)));
final loginProvider = Provider((ref) => Login(ref.watch(authRepositoryProvider)));
final logoutProvider = Provider((ref) => Logout(ref.watch(authRepositoryProvider)));
