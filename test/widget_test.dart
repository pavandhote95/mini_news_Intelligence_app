import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_news_intelligence/features/auth/di/auth_providers.dart';
import 'package:mini_news_intelligence/features/auth/presentation/providers/auth_controller.dart';
import 'package:mini_news_intelligence/features/auth/presentation/screens/login_screen.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeAuthRepository authRepository;

  Widget buildApp() => ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
        child: const MaterialApp(home: LoginScreen()),
      );

  setUp(() => authRepository = FakeAuthRepository());

  testWidgets('shows validation errors for empty form', (tester) async {
    await tester.pumpWidget(buildApp());

    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(authRepository.user, isNull);
  });

  testWidgets('valid credentials log the user in and persist the session', (tester) async {
    await tester.pumpWidget(buildApp());

    await tester.enterText(find.byKey(const Key('login_email')), 'jane@acme.com');
    await tester.enterText(find.byKey(const Key('login_password')), 'secret123');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.byType(LoginScreen)));
    expect(container.read(authControllerProvider).isAuthenticated, isTrue);
    expect(authRepository.getCurrentUser()?.email, 'jane@acme.com');
  });
}
