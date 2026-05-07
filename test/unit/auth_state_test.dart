import 'package:flutter_test/flutter_test.dart';
import 'package:digital_card/features/auth/providers/auth_provider.dart';
import 'package:digital_card/features/auth/domain/user_model.dart';

void main() {
  group('AuthState', () {
    test('initial state is AuthInitial', () {
      const state = AuthState.initial();
      expect(state, isA<AuthInitial>());
    });

    test('authenticated state holds user', () {
      final now = DateTime(2024);
      final user = UserModel(id: '1', email: 'a@b.com', name: 'Test', role: UserRole.employer, createdAt: now, updatedAt: now);
      final state = AuthState.authenticated(user);
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).user.email, 'a@b.com');
    });

    test('error state holds message', () {
      const state = AuthState.error('Something went wrong');
      expect(state, isA<AuthError>());
      expect((state as AuthError).message, 'Something went wrong');
    });

    test('unauthenticated state is distinct type', () {
      const state = AuthState.unauthenticated();
      expect(state, isA<AuthUnauthenticated>());
    });

    test('loading state is distinct type', () {
      const state = AuthState.loading();
      expect(state, isA<AuthLoading>());
    });
  });
}
