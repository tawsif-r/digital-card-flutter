import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';
import '../../../core/di/providers.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/constants.dart';

class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._repo, this._storage);

  final AuthRepository _repo;
  final SecureStorage _storage;

  AuthState _state = const AuthState.initial();
  AuthState get state => _state;

  UserModel? get user => switch (_state) {
        AuthAuthenticated(:final user) => user,
        _ => null,
      };

  bool get isAuthenticated => _state is AuthAuthenticated;

  Future<void> checkSession() async {
    _emit(const AuthState.loading());
    final token = await _storage.read(StorageKeys.accessToken);
    if (token == null) {
      _emit(const AuthState.unauthenticated());
      return;
    }
    try {
      final user = await _repo.getMe();
      _emit(AuthState.authenticated(user));
    } catch (_) {
      _emit(const AuthState.unauthenticated());
    }
  }

  Future<void> login(String email, String password) async {
    _emit(const AuthState.loading());
    try {
      final user = await _repo.login(email: email, password: password);
      _emit(AuthState.authenticated(user));
    } on Exception catch (e) {
      _emit(AuthState.error(_extractMessage(e)));
    }
  }

  Future<void> register(String email, String password, String? name) async {
    _emit(const AuthState.loading());
    try {
      final user = await _repo.register(email: email, password: password, name: name);
      _emit(AuthState.authenticated(user));
    } on Exception catch (e) {
      _emit(AuthState.error(_extractMessage(e)));
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    _emit(const AuthState.unauthenticated());
  }

  void forceLogout() {
    _emit(const AuthState.unauthenticated());
  }

  void clearError() {
    if (_state is AuthError) _emit(const AuthState.unauthenticated());
  }

  void _emit(AuthState next) {
    _state = next;
    notifyListeners();
  }

  String _extractMessage(Exception e) {
    final msg = e.toString();
    if (msg.contains('401')) return 'Invalid email or password.';
    if (msg.contains('409')) return 'Email already registered.';
    if (msg.contains('429')) return 'Too many attempts. Please wait.';
    return 'Something went wrong. Please try again.';
  }
}

sealed class AuthState {
  const AuthState();
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated(UserModel user) = AuthAuthenticated;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.error(String message) = AuthError;
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final UserModel user;
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
  );
});

final authProvider = ChangeNotifierProvider<AuthNotifier>((ref) {
  final notifier = AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(secureStorageProvider),
  );
  // Wire forceLogout into the interceptor so 401-on-refresh navigates to login
  ref.read(authInterceptorProvider).onUnauthenticated = notifier.forceLogout;
  return notifier;
});
